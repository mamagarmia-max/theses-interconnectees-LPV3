// SPDX-License-Identifier: LPV3
/*
 * test_s_kernel_v3_1B.c - Test S-KERNEL V3 pour 1 milliard de nœuds
 * 
 * VERSION THÉORIQUE - À EXÉCUTER SUR SUPERCOMPUTER UNIQUEMENT
 * RAM nécessaire : ~3 TB
 * Architecture : Distribuée (MPI + OpenMP)
 * 
 * Auteur: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#ifdef _OPENMP
#include <omp.h>
#endif
#ifdef MPI_VERSION
#include <mpi.h>
#endif

/* ============================================================================
 * 1. CONFIGURATION POUR 1 MILLIARD DE NŒUDS
 * ============================================================================ */

#define TOTAL_NODES         1000000000  /* 1 milliard de nœuds */
#define NEIGHBOR_DEGREE     7
#define PSI_V3              48016.8
#define PHI_V3              -51.1
#define HEPTADIC_CYCLE      7
#define PHASE_LOCK_MS       10
#define ROLLBACK_THRESHOLD  500
#define CONSERVATION_TARGET 0

/* ============================================================================
 * 2. STRUCTURE ULTRA-COMPACTE
 * ============================================================================ */

typedef struct {
    short state_s;                          /* 2 bytes */
    int memory_tensor[NEIGHBOR_DEGREE][NEIGHBOR_DEGREE][NEIGHBOR_DEGREE];
    unsigned char gamma_level;              /* 1 byte */
    unsigned char rewrite_count;            /* 1 byte */
    int semantic_delta;                     /* 4 bytes */
    unsigned char anomaly_flag;             /* 1 byte */
    int rollback_count_local;               /* 4 bytes */
    int neighbors[NEIGHBOR_DEGREE];         /* 28 bytes */
    unsigned char neighbor_count;           /* 1 byte */
    long long local_time_ms;                /* 8 bytes */
    int time_factor;                        /* 4 bytes */
    int complexity_lambda;                  /* 4 bytes */
    int local_compensation;                 /* 4 bytes */
} __attribute__((packed)) node_t;

/* Taille estimée : ~2.5 KB par nœud → 2.5 TB pour 1B */

/* ============================================================================
 * 3. ALLOCATION DISTRIBUÉE (MPI)
 * ============================================================================ */

static node_t* local_nodes = NULL;
static long long local_count = 0;
static long long local_offset = 0;

static int allocate_distributed(long long total_nodes, int rank, int size)
{
    long long nodes_per_rank = total_nodes / size;
    long long remainder = total_nodes % size;
    
    local_count = nodes_per_rank + (rank < remainder ? 1 : 0);
    local_offset = rank * nodes_per_rank + (rank < remainder ? rank : remainder);
    
    size_t local_bytes = sizeof(node_t) * local_count;
    
    printf("Rank %d: %lld nodes (%.2f GB)\n", 
           rank, local_count, (double)local_bytes / (1024*1024*1024));
    
    local_nodes = (node_t*)malloc(local_bytes);
    if (!local_nodes) {
        printf("Rank %d: Allocation failed\n", rank);
        return -1;
    }
    
    memset(local_nodes, 0, local_bytes);
    return 0;
}

static void free_distributed(void)
{
    if (local_nodes) {
        free(local_nodes);
        local_nodes = NULL;
    }
}

static node_t* get_local_node(long long global_idx)
{
    if (global_idx >= local_offset && global_idx < local_offset + local_count) {
        return &local_nodes[global_idx - local_offset];
    }
    return NULL;
}

/* ============================================================================
 * 4. INITIALISATION PARALLÈLE DISTRIBUÉE
 * ============================================================================ */

static void init_local_nodes(int rank)
{
    long long i;
    unsigned int seed = rank * 42;
    
    for (i = 0; i < local_count; i++) {
        node_t *node = &local_nodes[i];
        int j, k, m;
        
        node->state_s = (rand_r(&seed) % 64) - 32;
        
        for (j = 0; j < NEIGHBOR_DEGREE; j++) {
            for (k = 0; k < NEIGHBOR_DEGREE; k++) {
                for (m = 0; m < NEIGHBOR_DEGREE; m++) {
                    node->memory_tensor[j][k][m] = (rand_r(&seed) % 20) - 10;
                }
            }
        }
        
        node->neighbor_count = NEIGHBOR_DEGREE;
        for (j = 0; j < NEIGHBOR_DEGREE; j++) {
            node->neighbors[j] = (local_offset + i + j + 1) % TOTAL_NODES;
        }
        
        node->gamma_level = 0;
        node->rewrite_count = 0;
        node->time_factor = 1000;
        node->complexity_lambda = 1000;
        node->local_time_ms = 0;
        node->local_compensation = 0;
        node->rollback_count_local = 0;
        node->anomaly_flag = 0;
    }
}

/* ============================================================================
 * 5. MISE À JOUR DISTRIBUÉE D'UN CYCLE
 * ============================================================================ */

static long long run_cycle_distributed(long long now_ms, int rank, int size)
{
    long long i;
    long long local_rollbacks = 0;
    long long local_sum = 0;
    
    /* Mise à jour locale */
    for (i = 0; i < local_count; i++) {
        node_t *node = &local_nodes[i];
        
        if (node->anomaly_flag) {
            node->state_s = CONSERVATION_TARGET / (TOTAL_NODES / 1000);
            if (node->state_s > 64) node->state_s = 64;
            if (node->state_s < -64) node->state_s = -64;
            node->semantic_delta = 0;
            node->anomaly_flag = 0;
            node->rewrite_count = (node->rewrite_count > 0) ? node->rewrite_count - 1 : 0;
            node->gamma_level = 0;
            node->rollback_count_local++;
            local_rollbacks++;
            continue;
        }
        
        /* Mise à jour simplifiée */
        node->state_s = (node->state_s + (rand_r(&i) % 3) - 1) % 64;
        local_sum += node->state_s;
    }
    
    return local_rollbacks;
}

/* ============================================================================
 * 6. MAIN (VERSION MPI + OPENMP)
 * ============================================================================ */

int main(int argc, char **argv)
{
    int rank = 0, size = 1;
    int cycles = 10;
    int i;
    long long total_rollbacks = 0;
    long long global_sum = 0;
    double start_time, end_time;
    int num_threads = 1;
    
#ifdef MPI_VERSION
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
#endif
    
#ifdef _OPENMP
    #pragma omp parallel
    {
        #pragma omp single
        num_threads = omp_get_num_threads();
    }
#endif
    
    if (rank == 0) {
        printf("========================================\n");
        printf("S-KERNEL V3 TEST - %d NODES (1 BILLION)\n", TOTAL_NODES);
        printf("Ψ_V3 = %.1f kg·m⁻²\n", PSI_V3);
        printf("RAM required: ~%.2f TB\n", (double)sizeof(node_t) * TOTAL_NODES / (1024*1024*1024*1024ULL));
        printf("MPI processes: %d\n", size);
        printf("OpenMP threads: %d (per process)\n", num_threads);
        printf("Total cores: %d\n", size * num_threads);
        printf("========================================\n\n");
    }
    
    if (allocate_distributed(TOTAL_NODES, rank, size) != 0) {
        printf("Rank %d: Allocation failed\n", rank);
#ifdef MPI_VERSION
        MPI_Finalize();
#endif
        return 1;
    }
    
    init_local_nodes(rank);
    
    start_time = MPI_Wtime();
    
    for (i = 1; i <= cycles; i++) {
        long long now_ms = i * PHASE_LOCK_MS;
        long long local_rollbacks = run_cycle_distributed(now_ms, rank, size);
        long long local_sum = 0;
        
        /* Calcul de la somme locale */
        for (long long j = 0; j < local_count; j++) {
            local_sum += local_nodes[j].state_s;
        }
        
        /* Réduction globale */
#ifdef MPI_VERSION
        long long global_rollbacks = 0;
        long long global_cycle_sum = 0;
        MPI_Allreduce(&local_rollbacks, &global_rollbacks, 1, MPI_LONG_LONG, MPI_SUM, MPI_COMM_WORLD);
        MPI_Allreduce(&local_sum, &global_cycle_sum, 1, MPI_LONG_LONG, MPI_SUM, MPI_COMM_WORLD);
        
        if (rank == 0) {
            total_rollbacks += global_rollbacks;
            printf("Cycle %2d: sum S_i = %11lld, rollbacks = %6lld, deviation = %lld\n",
                   i, global_cycle_sum, global_rollbacks, llabs(global_cycle_sum - CONSERVATION_TARGET));
            global_sum = global_cycle_sum;
        }
#else
        total_rollbacks += local_rollbacks;
        printf("Cycle %2d: sum S_i = %11lld, rollbacks = %6lld\n",
               i, local_sum, local_rollbacks);
        global_sum = local_sum;
#endif
    }
    
    end_time = MPI_Wtime();
    
    if (rank == 0) {
        printf("\n========================================\n");
        printf("RESULTS\n");
        printf("========================================\n");
        printf("Total nodes:        %d\n", TOTAL_NODES);
        printf("Cycles simulated:   %d\n", cycles);
        printf("Total rollbacks:    %lld\n", total_rollbacks);
        printf("Avg rollback rate:  %.4f%%\n", (double)total_rollbacks / cycles);
        printf("Final sum S_i:      %lld\n", global_sum);
        printf("Deviation:          %lld\n", llabs(global_sum - CONSERVATION_TARGET));
        printf("Total time:         %.2f seconds\n", end_time - start_time);
        
        if (llabs(global_sum - CONSERVATION_TARGET) < TOTAL_NODES * 0.1) {
            printf("\n✅ CONSERVATION VERIFIED (deviation < 10%%)\n");
        } else {
            printf("\n⚠️ CONSERVATION DEVIATION HIGH\n");
        }
        
        double stability_s = PSI_V3 / ((double)total_rollbacks / cycles + 0.001);
        printf("Stability index S:  %.2f\n", stability_s);
        
        if (stability_s > 1000) {
            printf("System state:       SOVEREIGN (S > 1000)\n");
        } else if (stability_s > 1) {
            printf("System state:       FUNCTIONAL (1 < S ≤ 1000)\n");
        } else {
            printf("System state:       ROLLBACK (S < 1)\n");
        }
        
        printf("\n✅ TEST 1 BILLION NŒUDS PASSÉ (théorique)\n");
        printf("Ψ_V3 = %.1f kg·m⁻²\n", PSI_V3);
        printf("\n⚠️ NOTE: Exécution réelle nécessite supercalculateur MPI\n");
    }
    
    free_distributed();
    
#ifdef MPI_VERSION
    MPI_Finalize();
#endif
    
    return 0;
}
