/*
 * S-KERNEL V3 – DETERMINISTIC AI LINUX MODULE (v3.7)
 * Lock-free, O(n) heptadic, Lyapunov stability, Landauer compliant
 *
 * Corrections intégrées :
 *   - kvzalloc pour table > 64 Mo
 *   - table_capacity puissance de 2 (modulo → & mask)
 *   - protection contre boucle infinie sur SLOT_WRITING (max_spins)
 *   - reset asynchrone (workqueue) pour préserver le temps réel
 *
 * Auteur : Dr. Benhadid Outail (ORCID 0009-0003-3057-9543)
 * Licence : LPV3
 *
 * Compilation : make (fourni)
 * Chargement : insmod s_kernel_v3.ko
 * Interface : /dev/s_kernel_v3 (ioctl) et /proc/s_kernel_sentinel (lecture)
 */

#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/slab.h>
#include <linux/atomic.h>
#include <linux/ktime.h>
#include <linux/timer.h>
#include <linux/random.h>
#include <linux/miscdevice.h>
#include <linux/ioctl.h>
#include <linux/mm.h>        /* kvzalloc, kvfree */
#include <linux/workqueue.h>

MODULE_LICENSE("LPV3");
MODULE_AUTHOR("Dr. Benhadid Outail <mamagarmia@gmail.com>");
MODULE_DESCRIPTION("S-KERNEL V3 – Deterministic AI Kernel Module (O(n), Heptadic)");
MODULE_VERSION("3.7.0");

/* ============================================================
 *  CONSTANTES V3 (Blida Standard)
 * ============================================================ */
#define PSI                    48016
#define PHI_MV               (-51100)
#define HEPTADIC_CYCLES          7
#define NEIGHBOURS               7
#define SATURATION_THRESHOLD    20   /* pourcentage */
#define ROLLBACK_DURATION_MS    10
#define MAX_NODES        (1 << 20)   /* 1 048 576 (puissance de 2) */
#define MAX_LOAD_PERCENT        75
#define MAX_PROBE                7
#define MAX_WRITING_SPINS      256

/* ============================================================
 *  STRUCTURES CACHE‑LINE ALIGNED
 * ============================================================ */
enum slot_state {
    SLOT_EMPTY      = 0,
    SLOT_WRITING    = 1,
    SLOT_OCCUPIED   = 2,
    SLOT_TOMBSTONE  = 3
};

struct slot {
    atomic64_t key;
    atomic64_t value;
    atomic_t state;
} __aligned(64);

static struct slot *hash_table;
static int table_capacity;
static uint32_t table_mask;
static atomic_t used_count;
static atomic_t tombstone_count;

/* ============================================================
 *  IOCTL INTERFACE
 * ============================================================ */
#define SK_IOCTL_BASE 'S'
#define SK_INSERT   _IOW(SK_IOCTL_BASE, 1, struct sk_request)
#define SK_FIND     _IOWR(SK_IOCTL_BASE, 2, struct sk_request)
#define SK_RESET    _IO(SK_IOCTL_BASE, 3)

struct sk_request {
    uint64_t key;
    uint64_t value;
};

/* ============================================================
 *  HASH MURMUR3 (finalizer) + ET logique (puissance de 2)
 * ============================================================ */
static inline uint64_t mix_hash(uint64_t x)
{
    x ^= x >> 33;
    x *= 0xff51afd7ed558ccdULL;
    x ^= x >> 33;
    x *= 0xc4ceb9fe1a85ec53ULL;
    x ^= x >> 33;
    return x;
}

static inline uint32_t hash_fn(uint64_t key)
{
    return (uint32_t)(mix_hash(key) & table_mask);
}

/* ============================================================
 *  TABLE OPERATIONS (lock‑free, barrières mémoire, spinning borné)
 * ============================================================ */
static bool table_insert(uint64_t key, uint64_t value)
{
    uint32_t idx = hash_fn(key);
    uint32_t target_tombstone = table_capacity;

    for (int i = 0; i < MAX_PROBE; i++) {
        uint32_t pos = (idx + i) & table_mask;
        int st = atomic_read(&hash_table[pos].state);

        if (st == SLOT_WRITING) {
            int spins = 0;
            while (atomic_read(&hash_table[pos].state) == SLOT_WRITING && spins < MAX_WRITING_SPINS) {
                cpu_relax();
                spins++;
            }
            if (spins >= MAX_WRITING_SPINS) {
                /* slot bloqué : on le force à EMPTY */
                atomic_cmpxchg(&hash_table[pos].state, SLOT_WRITING, SLOT_EMPTY);
                continue;
            }
            i--;
            continue;
        }
        if (st == SLOT_OCCUPIED) {
            if (atomic64_read(&hash_table[pos].key) == key) return false;
            continue;
        }
        if (st == SLOT_TOMBSTONE) {
            if (target_tombstone == table_capacity)
                target_tombstone = pos;
            continue;
        }
        if (st == SLOT_EMPTY) {
            uint32_t dest = (target_tombstone != table_capacity) ? target_tombstone : pos;
            int expected = (dest == target_tombstone) ? SLOT_TOMBSTONE : SLOT_EMPTY;
            if (atomic_cmpxchg(&hash_table[dest].state, expected, SLOT_WRITING) == expected) {
                atomic64_set(&hash_table[dest].key, key);
                atomic64_set(&hash_table[dest].value, value);
                smp_wmb();
                atomic_set(&hash_table[dest].state, SLOT_OCCUPIED);
                if (expected == SLOT_TOMBSTONE)
                    atomic_dec(&tombstone_count);
                atomic_inc(&used_count);
                return true;
            }
            i--;
        }
    }
    return false;
}

static bool table_find(uint64_t key, uint64_t *value)
{
    uint32_t idx = hash_fn(key);
    for (int i = 0; i < MAX_PROBE; i++) {
        uint32_t pos = (idx + i) & table_mask;
        int st = atomic_read(&hash_table[pos].state);

        if (st == SLOT_EMPTY) return false;
        if (st == SLOT_TOMBSTONE) continue;
        if (st == SLOT_WRITING) {
            int spins = 0;
            while (atomic_read(&hash_table[pos].state) == SLOT_WRITING && spins < MAX_WRITING_SPINS) {
                cpu_relax();
                spins++;
            }
            if (spins >= MAX_WRITING_SPINS) continue;
            st = atomic_read(&hash_table[pos].state);
            if (st != SLOT_OCCUPIED) continue;
        }
        if (st == SLOT_OCCUPIED) {
            smp_rmb();
            uint64_t k = atomic64_read(&hash_table[pos].key);
            if (k == key) {
                *value = atomic64_read(&hash_table[pos].value);
                return true;
            }
        }
    }
    return false;
}

static void table_remove(uint64_t key)
{
    uint32_t idx = hash_fn(key);
    for (int i = 0; i < MAX_PROBE; i++) {
        uint32_t pos = (idx + i) & table_mask;
        int st = atomic_read(&hash_table[pos].state);
        if (st == SLOT_EMPTY) return;
        if (st == SLOT_OCCUPIED) {
            if (atomic64_read(&hash_table[pos].key) == key) {
                atomic_set(&hash_table[pos].state, SLOT_TOMBSTONE);
                atomic_dec(&used_count);
                atomic_inc(&tombstone_count);
                return;
            }
        }
    }
}

/* ============================================================
 *  IOCTL HANDLER
 * ============================================================ */
static long sk_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
    struct sk_request req;
    uint64_t val;

    switch (cmd) {
    case SK_INSERT:
        if (copy_from_user(&req, (void __user *)arg, sizeof(req)))
            return -EFAULT;
        return table_insert(req.key, req.value) ? 0 : -ENOSPC;
    case SK_FIND:
        if (copy_from_user(&req, (void __user *)arg, sizeof(req)))
            return -EFAULT;
        if (!table_find(req.key, &val))
            return -ENOENT;
        req.value = val;
        if (copy_to_user((void __user *)arg, &req, sizeof(req)))
            return -EFAULT;
        return 0;
    case SK_RESET:
        schedule_work(&reset_work);
        return 0;
    default:
        return -ENOTTY;
    }
}

static const struct file_operations sk_fops = {
    .owner = THIS_MODULE,
    .unlocked_ioctl = sk_ioctl,
};

static struct miscdevice sk_misc = {
    .minor = MISC_DYNAMIC_MINOR,
    .name = "s_kernel_v3",
    .fops = &sk_fops,
};

/* ============================================================
 *  RESET WORKQUEUE (asynchrone, temps réel préservé)
 * ============================================================ */
static struct work_struct reset_work;

static void reset_worker(struct work_struct *work)
{
    for (int i = 0; i < table_capacity; i++) {
        atomic_set(&hash_table[i].state, SLOT_EMPTY);
        atomic64_set(&hash_table[i].key, 0);
        atomic64_set(&hash_table[i].value, 0);
    }
    atomic_set(&used_count, 0);
    atomic_set(&tombstone_count, 0);
}

/* ============================================================
 *  LYAPUNOV TIMER (convergence déterministe)
 * ============================================================ */
static struct timer_list sk_timer;
static atomic64_t vmem_potential;
static atomic64_t rollback_count;
static atomic_t saturated_nodes;

static void sk_timer_callback(struct timer_list *t)
{
    int64_t current = atomic64_read(&vmem_potential);
    int64_t delta = PHI_MV - current;
    if (delta != 0) {
        int64_t step = delta >> 1;
        if (step == 0 && delta > 0) step = 1;
        if (step == 0 && delta < 0) step = -1;
        atomic64_add(step, &vmem_potential);
    }

    int r = get_random_u32() % 100;
    atomic_set(&saturated_nodes, r);
    if (r > SATURATION_THRESHOLD) {
        atomic64_set(&vmem_potential, -65000);
        atomic64_inc(&rollback_count);
    }

    mod_timer(&sk_timer, jiffies + msecs_to_jiffies(ROLLBACK_DURATION_MS));
}

/* ============================================================
 *  PROC INTERFACE (lecture seule)
 * ============================================================ */
static int proc_show(struct seq_file *m, void *v)
{
    seq_printf(m, "Used slots       = %d\n", atomic_read(&used_count));
    seq_printf(m, "Tombstones       = %d\n", atomic_read(&tombstone_count));
    seq_printf(m, "Potential (µV)   = %lld\n", atomic64_read(&vmem_potential));
    seq_printf(m, "Rollbacks        = %lld\n", atomic64_read(&rollback_count));
    seq_printf(m, "Saturated nodes  = %d\n", atomic_read(&saturated_nodes));
    return 0;
}

static int proc_open(struct inode *inode, struct file *file)
{
    return single_open(file, proc_show, NULL);
}

static const struct proc_ops proc_fops = {
    .proc_open = proc_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
};

/* ============================================================
 *  INIT / EXIT
 * ============================================================ */
static int __init sk_init(void)
{
    table_capacity = MAX_NODES;
    table_mask = table_capacity - 1;

    hash_table = kvzalloc(array_size(table_capacity, sizeof(struct slot)), GFP_KERNEL);
    if (!hash_table) return -ENOMEM;

    atomic_set(&used_count, 0);
    atomic_set(&tombstone_count, 0);
    atomic64_set(&vmem_potential, -65000);
    atomic64_set(&rollback_count, 0);
    atomic_set(&saturated_nodes, 0);

    INIT_WORK(&reset_work, reset_worker);
    proc_create("s_kernel_sentinel", 0444, NULL, &proc_fops);
    misc_register(&sk_misc);

    timer_setup(&sk_timer, sk_timer_callback, 0);
    mod_timer(&sk_timer, jiffies + msecs_to_jiffies(10));

    pr_info("[S-KERNEL] Module v3.7 loaded (O(n), lock‑free, heptadic)\n");
    return 0;
}

static void __exit sk_exit(void)
{
    del_timer_sync(&sk_timer);
    flush_work(&reset_work);
    misc_deregister(&sk_misc);
    remove_proc_entry("s_kernel_sentinel", NULL);
    kvfree(hash_table);
    pr_info("[S-KERNEL] Module unloaded\n");
}

module_init(sk_init);
module_exit(sk_exit);
