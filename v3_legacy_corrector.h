/*
 * v3_legacy_corrector.h - V3 Semantic Corrector for Legacy Code
 *
 * NC/SP V3 SOVEREIGN ARCHITECTURE - ADAPTIVE CORRECTION LAYER
 *
 * This header provides a configurable correction layer for existing code.
 * It intercepts function calls via LD_PRELOAD, monitors execution,
 * and applies user-selected correction modes.
 *
 * CORRECTION MODES (set via V3_CORRECTION_MODE environment variable):
 *
 * MODE 0 - PASSIVE (Diagnostic only)
 *   - Detects anomalies, logs violations, no action
 *   - Risk: none
 *
 * MODE 1 - ALERT (Visual notification)
 *   - Detects anomalies, logs, prints to stderr with color
 *   - Risk: none
 *
 * MODE 2 - THROTTLE (Slow down on anomaly)
 *   - Detects anomalies, adds microsecond delay on violation
 *   - Risk: minimal (performance only)
 *
 * MODE 3 - RETURN_SAFE (Replace return value)
 *   - Detects anomalies, returns safe default (0/NULL) on violation
 *   - Risk: moderate (may hide errors)
 *
 * MODE 4 - RETRY (Re-execute function)
 *   - Detects anomalies, retries up to 3 times before returning
 *   - Risk: moderate (may loop)
 *
 * MODE 5 - ROLLBACK (Restore last known good state)
 *   - Detects anomalies, returns last cached successful value
 *   - Risk: elevated (state may be stale)
 *
 * MODE 6 - ISOLATE (Mark function as unavailable)
 *   - First anomaly = warning, second = blacklist, subsequent = immediate safe return
 *   - Risk: elevated (function effectively disabled)
 *
 * MODE 7 - FALLBACK (Call alternative function)
 *   - Detects anomalies, calls backup function instead
 *   - Risk: moderate (depends on fallback quality)
 *
 * MODE 8 - LOG_ONLY_CRITICAL (Selective logging)
 *   - Logs only critical anomalies (latency > 10000ns)
 *   - Risk: none
 *
 * MODE 9 - ADAPTIVE (Auto-adjust based on history)
 *   - Starts in PASSIVE, escalates mode if anomaly rate > threshold
 *   - Risk: variable (auto-escalation)
 *
 * Usage:
 *   export V3_CORRECTION_MODE=0   (passive)
 *   export V3_CORRECTION_MODE=3   (return safe)
 *   LD_PRELOAD=./v3_legacy_corrector.so ./your_binary
 *
 * Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
 * License: LPV3 (DOI: 10.5281/zenodo.19209168)
 * Standard: V3
 */

#ifndef V3_LEGACY_CORRECTOR_H
#define V3_LEGACY_CORRECTOR_H

#include <stdint.h>
#include <stddef.h>
#include <time.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>

/* ============================================================================
 * 1. V3 INVARIANTS
 * ============================================================================
 */

#define PSI_V3_INVARIANT           480168ULL
#define PHI_V3_ATTRACTOR           -51100LL
#define WARNING_THRESHOLD_NS       1562ULL
#define CRITICAL_THRESHOLD_NS      10000ULL
#define MAX_LOG_ENTRIES            4096U
#define MAX_RETRY_COUNT            3U
#define CACHELINE_SIZE             64U
#define ANOMALY_RATE_ESCALATION    20U    /* 20% anomalies triggers escalation */

/* Correction modes */
#define V3_MODE_PASSIVE            0
#define V3_MODE_ALERT              1
#define V3_MODE_THROTTLE           2
#define V3_MODE_RETURN_SAFE        3
#define V3_MODE_RETRY              4
#define V3_MODE_ROLLBACK           5
#define V3_MODE_ISOLATE            6
#define V3_MODE_FALLBACK           7
#define V3_MODE_LOG_ONLY_CRITICAL  8
#define V3_MODE_ADAPTIVE           9

/* ============================================================================
 * 2. STATIC MEMORY POOL
 * ============================================================================
 */

typedef struct __attribute__((aligned(CACHELINE_SIZE))) {
    uint64_t    timestamp_ns;
    uint64_t    function_id;
    uint64_t    latency_ns;
    uint64_t    return_value;
    uint64_t    cached_safe_value;
    uint8_t     anomaly_type;
    uint8_t     retry_count;
    uint8_t     is_blacklisted;
    uint8_t     _pad[5];
} V3_LogEntry;

typedef struct __attribute__((aligned(CACHELINE_SIZE))) {
    uint64_t    call_count;
    uint64_t    anomaly_count;
    uint64_t    warning_count;
    uint64_t    critical_count;
    uint64_t    min_latency_ns;
    uint64_t    max_latency_ns;
    uint64_t    total_latency_ns;
    uint64_t    last_safe_return;
    uint64_t    fallback_function_id;
    uint8_t     current_mode;
    uint8_t     is_blacklisted;
    uint8_t     consecutive_anomalies;
    uint8_t     adaptive_escalated;
    uint8_t     _pad[2];
} V3_Stats;

/* Global static pools */
static V3_Stats v3_stats[128] __attribute__((aligned(CACHELINE_SIZE)));
static V3_LogEntry v3_log[MAX_LOG_ENTRIES] __attribute__((aligned(CACHELINE_SIZE)));
static uint64_t v3_log_index __attribute__((aligned(CACHELINE_SIZE))) = 0;
static uint8_t v3_global_mode __attribute__((aligned(CACHELINE_SIZE))) = V3_MODE_PASSIVE;
static uint8_t v3_initialized = 0;

/* Fallback function registry */
static void* (*v3_fallback_functions[128])(void*) = {NULL};

/* ============================================================================
 * 3. Configuration from Environment
 * ============================================================================
 */

static void v3_init_config(void)
{
    char *env = getenv("V3_CORRECTION_MODE");
    if (env) {
        int mode = atoi(env);
        if (mode >= V3_MODE_PASSIVE && mode <= V3_MODE_ADAPTIVE) {
            v3_global_mode = (uint8_t)mode;
        }
    }
    
    fprintf(stderr, "[V3] Correction mode: %d\n", v3_global_mode);
}

/* ============================================================================
 * 4. High-Resolution Timer
 * ============================================================================
 */

static inline uint64_t v3_nanotime(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

/* ============================================================================
 * 5. Fixed-Point Utilities
 * ============================================================================
 */

static inline uint64_t fixed_mul_saturate(uint64_t a, uint64_t b, uint64_t scale)
{
    if (a > (UINT64_MAX / b))
        return UINT64_MAX;
    return (a * b) / scale;
}

/* ============================================================================
 * 6. Anomaly Detection
 * ============================================================================
 */

static inline int v3_detect_anomaly(uint64_t elapsed_ns, V3_Stats *stats, uint64_t func_id)
{
    uint64_t normalized_error;
    int anomaly_type = 0;
    
    /* Update statistics */
    if (elapsed_ns < stats->min_latency_ns || stats->min_latency_ns == 0)
        stats->min_latency_ns = elapsed_ns;
    if (elapsed_ns > stats->max_latency_ns)
        stats->max_latency_ns = elapsed_ns;
    stats->total_latency_ns += elapsed_ns;
    stats->call_count++;
    
    /* Normalize against Ψ_V₃ and check against Φ_V₃ */
    normalized_error = fixed_mul_saturate(elapsed_ns, 10000, PSI_V3_INVARIANT / 1000);
    
    if (normalized_error > (uint64_t)(-PHI_V3_ATTRACTOR)) {
        anomaly_type = 1;
        stats->anomaly_count++;
        stats->consecutive_anomalies++;
        
        if (elapsed_ns > CRITICAL_THRESHOLD_NS) {
            anomaly_type = 3;
            stats->critical_count++;
        } else if (elapsed_ns > WARNING_THRESHOLD_NS) {
            anomaly_type = 2;
            stats->warning_count++;
        }
    } else {
        stats->consecutive_anomalies = 0;
    }
    
    /* Adaptive mode: escalate if anomaly rate > threshold */
    if (stats->current_mode == V3_MODE_ADAPTIVE && !stats->adaptive_escalated) {
        if (stats->anomaly_count > (stats->call_count * ANOMALY_RATE_ESCALATION / 100)) {
            stats->adaptive_escalated = 1;
            stats->current_mode = V3_MODE_RETURN_SAFE;
            fprintf(stderr, "[V3] Adaptive escalation: mode PASSIVE -> RETURN_SAFE for func %llu\n",
                    (unsigned long long)func_id);
        }
    }
    
    return anomaly_type;
}

/* ============================================================================
 * 7. Correction Actions Based on Mode
 * ============================================================================
 */

static inline uint64_t v3_apply_correction(V3_Stats *stats, uint64_t func_id, 
                                            uint64_t original_return, 
                                            uint64_t elapsed_ns,
                                            int anomaly_type)
{
    uint64_t result = original_return;
    uint8_t mode = (stats->current_mode != V3_MODE_ADAPTIVE) ? stats->current_mode : v3_global_mode;
    int i;
    
    /* If blacklisted, immediately return safe value */
    if (stats->is_blacklisted && mode >= V3_MODE_ISOLATE) {
        return stats->last_safe_return;
    }
    
    switch (mode) {
        case V3_MODE_PASSIVE:
            /* No action, just return original */
            break;
            
        case V3_MODE_ALERT:
            if (anomaly_type) {
                fprintf(stderr, "\x1b[33m[V3] ALERT: func=%llu latency=%llu ns\x1b[0m\n",
                        (unsigned long long)func_id, (unsigned long long)elapsed_ns);
            }
            break;
            
        case V3_MODE_THROTTLE:
            if (anomaly_type) {
                usleep(100);  /* 100 microseconds throttle */
            }
            break;
            
        case V3_MODE_RETURN_SAFE:
            if (anomaly_type) {
                result = stats->last_safe_return;
                fprintf(stderr, "[V3] SAFE RETURN: func=%llu returned %llu (instead of %llu)\n",
                        (unsigned long long)func_id,
                        (unsigned long long)result,
                        (unsigned long long)original_return);
            }
            break;
            
        case V3_MODE_RETRY:
            if (anomaly_type && stats->retry_count < MAX_RETRY_COUNT) {
                stats->retry_count++;
                fprintf(stderr, "[V3] RETRY: func=%llu attempt %d\n",
                        (unsigned long long)func_id, stats->retry_count);
                /* Signal retry needed - handled by caller */
                result = (uint64_t)-1;  /* Special marker for retry */
            }
            break;
            
        case V3_MODE_ROLLBACK:
            if (anomaly_type) {
                result = stats->last_safe_return;
                stats->rollback_count++;
                fprintf(stderr, "[V3] ROLLBACK: func=%llu using cached value %llu\n",
                        (unsigned long long)func_id,
                        (unsigned long long)result);
            } else {
                stats->last_safe_return = original_return;
            }
            break;
            
        case V3_MODE_ISOLATE:
            if (anomaly_type) {
                stats->consecutive_anomalies++;
                if (stats->consecutive_anomalies >= 2) {
                    stats->is_blacklisted = 1;
                    result = stats->last_safe_return;
                    fprintf(stderr, "[V3] ISOLATE: func=%llu BLACKLISTED\n",
                            (unsigned long long)func_id);
                }
            } else {
                stats->consecutive_anomalies = 0;
                stats->last_safe_return = original_return;
            }
            break;
            
        case V3_MODE_FALLBACK:
            if (anomaly_type && v3_fallback_functions[func_id]) {
                /* Fallback would be called by wrapper */
                result = (uint64_t)-2;  /* Special marker for fallback */
            }
            break;
            
        case V3_MODE_LOG_ONLY_CRITICAL:
            if (anomaly_type < 3) {  /* Only log critical (type 3) */
                /* Suppress logging for non-critical */
                v3_log_index--;  /* Undo log entry */
            }
            break;
            
        case V3_MODE_ADAPTIVE:
            /* Already handled above */
            break;
    }
    
    return result;
}

/* ============================================================================
 * 8. Logging Function
 * ============================================================================
 */

static inline void v3_log_anomaly(uint64_t func_id, uint64_t latency_ns, 
                                   uint64_t return_value, int anomaly_type,
                                   uint64_t corrected_value)
{
    if (v3_log_index < MAX_LOG_ENTRIES) {
        v3_log[v3_log_index].timestamp_ns = v3_nanotime();
        v3_log[v3_log_index].function_id = func_id;
        v3_log[v3_log_index].latency_ns = latency_ns;
        v3_log[v3_log_index].return_value = corrected_value;
        v3_log[v3_log_index].cached_safe_value = return_value;
        v3_log[v3_log_index].anomaly_type = (uint8_t)anomaly_type;
        v3_log_index++;
    }
}

/* ============================================================================
 * 9. Main Monitoring and Correction Wrapper
 * ============================================================================
 */

static inline uint64_t v3_monitor_and_correct(uint64_t (*legacy_function)(void*), 
                                               void* context,
                                               V3_Stats *stats,
                                               uint64_t function_id)
{
    uint64_t start_ns, end_ns, elapsed_ns;
    uint64_t result;
    uint64_t corrected;
    int anomaly_type;
    int retry_count = 0;
    
    start_ns = v3_nanotime();
    result = legacy_function(context);
    end_ns = v3_nanotime();
    elapsed_ns = end_ns - start_ns;
    
    anomaly_type = v3_detect_anomaly(elapsed_ns, stats, function_id);
    
    corrected = v3_apply_correction(stats, function_id, result, elapsed_ns, anomaly_type);
    
    /* Handle retry mode (MODE_RETRY special case) */
    if (corrected == (uint64_t)-1 && retry_count < MAX_RETRY_COUNT) {
        retry_count++;
        start_ns = v3_nanotime();
        result = legacy_function(context);
        end_ns = v3_nanotime();
        elapsed_ns = end_ns - start_ns;
        anomaly_type = v3_detect_anomaly(elapsed_ns, stats, function_id);
        corrected = v3_apply_correction(stats, function_id, result, elapsed_ns, anomaly_type);
    }
    
    /* Handle fallback mode (MODE_FALLBACK special case) */
    if (corrected == (uint64_t)-2 && v3_fallback_functions[function_id]) {
        result = v3_fallback_functions[function_id](context);
        corrected = result;
        fprintf(stderr, "[V3] FALLBACK: used alternative for func %llu\n",
                (unsigned long long)function_id);
    }
    
    v3_log_anomaly(function_id, elapsed_ns, result, anomaly_type, corrected);
    
    /* Update safe cache for rollback mode */
    if (stats->current_mode == V3_MODE_ROLLBACK && anomaly_type == 0) {
        stats->last_safe_return = result;
    }
    
    return corrected;
}

/* ============================================================================
 * 10. LD_PRELOAD Wrappers with Correction Modes
 * ============================================================================
 */

static void* (*original_malloc)(size_t) = NULL;
static void (*original_free)(void*) = NULL;
static void* (*original_calloc)(size_t, size_t) = NULL;
static void* (*original_realloc)(void*, size_t) = NULL;
static void* (*original_memcpy)(void*, const void*, size_t) = NULL;

static V3_Stats malloc_stats = {0};
static V3_Stats free_stats = {0};
static V3_Stats calloc_stats = {0};
static V3_Stats realloc_stats = {0};
static V3_Stats memcpy_stats = {0};

void* malloc(size_t size)
{
    uint64_t start_ns, end_ns, elapsed_ns;
    void* result;
    int anomaly_type;
    
    if (!original_malloc) {
        original_malloc = (void*(*)(size_t)) dlsym(RTLD_NEXT, "malloc");
        malloc_stats.current_mode = v3_global_mode;
    }
    
    start_ns = v3_nanotime();
    result = original_malloc(size);
    end_ns = v3_nanotime();
    elapsed_ns = end_ns - start_ns;
    
    anomaly_type = v3_detect_anomaly(elapsed_ns, &malloc_stats, 1);
    
    if (anomaly_type && malloc_stats.current_mode >= V3_MODE_ALERT) {
        fprintf(stderr, "[V3] malloc(%zu) took %llu ns (anomaly)\n",
                size, (unsigned long long)elapsed_ns);
        if (malloc_stats.current_mode == V3_MODE_RETURN_SAFE) {
            return NULL;
        }
    }
    
    return result;
}

void free(void* ptr)
{
    uint64_t start_ns, end_ns;
    
    if (!original_free) {
        original_free = (void(*)(void*)) dlsym(RTLD_NEXT, "free");
        free_stats.current_mode = v3_global_mode;
    }
    
    start_ns = v3_nanotime();
    original_free(ptr);
    end_ns = v3_nanotime();
    
    v3_detect_anomaly(end_ns - start_ns, &free_stats, 2);
}

void* calloc(size_t nmemb, size_t size)
{
    uint64_t start_ns, end_ns;
    void* result;
    int anomaly_type;
    
    if (!original_calloc) {
        original_calloc = (void*(*)(size_t, size_t)) dlsym(RTLD_NEXT, "calloc");
        calloc_stats.current_mode = v3_global_mode;
    }
    
    start_ns = v3_nanotime();
    result = original_calloc(nmemb, size);
    end_ns = v3_nanotime();
    
    anomaly_type = v3_detect_anomaly(end_ns - start_ns, &calloc_stats, 3);
    
    if (anomaly_type && calloc_stats.current_mode >= V3_MODE_RETURN_SAFE) {
        return NULL;
    }
    
    return result;
}

void* realloc(void* ptr, size_t size)
{
    uint64_t start_ns, end_ns;
    void* result;
    int anomaly_type;
    
    if (!original_realloc) {
        original_realloc = (void*(*)(void*, size_t)) dlsym(RTLD_NEXT, "realloc");
        realloc_stats.current_mode = v3_global_mode;
    }
    
    start_ns = v3_nanotime();
    result = original_realloc(ptr, size);
    end_ns = v3_nanotime();
    
    anomaly_type = v3_detect_anomaly(end_ns - start_ns, &realloc_stats, 4);
    
    if (anomaly_type && realloc_stats.current_mode >= V3_MODE_RETURN_SAFE) {
        return NULL;
    }
    
    return result;
}

void* memcpy(void* dest, const void* src, size_t n)
{
    uint64_t start_ns, end_ns;
    void* result;
    int anomaly_type;
    
    if (!original_memcpy) {
        original_memcpy = (void*(*)(void*, const void*, size_t)) dlsym(RTLD_NEXT, "memcpy");
        memcpy_stats.current_mode = v3_global_mode;
    }
    
    start_ns = v3_nanotime();
    result = original_memcpy(dest, src, n);
    end_ns = v3_nanotime();
    
    anomaly_type = v3_detect_anomaly(end_ns - start_ns, &memcpy_stats, 5);
    
    return result;
}

/* ============================================================================
 * 11. Fallback Function Registration
 * ============================================================================
 */

void v3_register_fallback(uint64_t func_id, void* (*fallback)(void*))
{
    if (func_id < 128) {
        v3_fallback_functions[func_id] = fallback;
    }
}

/* ============================================================================
 * 12. Status Reporting
 * ============================================================================
 */

static void v3_print_status(void)
{
    uint64_t i;
    const char* mode_names[] = {
        "PASSIVE", "ALERT", "THROTTLE", "RETURN_SAFE",
        "RETRY", "ROLLBACK", "ISOLATE", "FALLBACK",
        "LOG_ONLY_CRITICAL", "ADAPTIVE"
    };
    
    printf("\n=== V3 LEGACY CORRECTOR - STATUS REPORT ===\n");
    printf("Ψ_V₃ = %llu.%llu kg·m⁻² | Φ_V₃ = %d mV\n",
           PSI_V3_INVARIANT / 10000, (PSI_V3_INVARIANT % 10000) / 1000,
           PHI_V3_ATTRACTOR);
    printf("Global mode: %s (%d)\n\n", mode_names[v3_global_mode], v3_global_mode);
    
    printf("malloc: calls=%llu anomalies=%llu warnings=%llu critical=%llu latency=[%llu/%llu/%llu]ns\n",
           (unsigned long long)malloc_stats.call_count,
           (unsigned long long)malloc_stats.anomaly_count,
           (unsigned long long)malloc_stats.warning_count,
           (unsigned long long)malloc_stats.critical_count,
           (unsigned long long)malloc_stats.min_latency_ns,
           (unsigned long long)(malloc_stats.total_latency_ns / (malloc_stats.call_count + 1)),
           (unsigned long long)malloc_stats.max_latency_ns);
    
    printf("free:   calls=%llu anomalies=%llu latency=[%llu/%llu/%llu]ns\n",
           (unsigned long long)free_stats.call_count,
           (unsigned long long)free_stats.anomaly_count,
           (unsigned long long)free_stats.min_latency_ns,
           (unsigned long long)(free_stats.total_latency_ns / (free_stats.call_count + 1)),
           (unsigned long long)free_stats.max_latency_ns);
    
    printf("Log entries: %llu / %d\n", (unsigned long long)v3_log_index, MAX_LOG_ENTRIES);
    
    if (v3_log_index > 0) {
        printf("\nLast 10 anomalies:\n");
        uint64_t start = (v3_log_index > 10) ? v3_log_index - 10 : 0;
        for (i = start; i < v3_log_index && i < MAX_LOG_ENTRIES; i++) {
            const char* type_str = (v3_log[i].anomaly_type == 1) ? "JITTER" :
                                   (v3_log[i].anomaly_type == 2) ? "WARNING" : "CRITICAL";
            printf("  [%llu] func=%llu latency=%llu ns type=%s corrected=%llu\n",
                   (unsigned long long)i,
                   (unsigned long long)v3_log[i].function_id,
                   (unsigned long long)v3_log[i].latency_ns, type_str,
                   (unsigned long long)v3_log[i].return_value);
        }
    }
    
    printf("\n=== END OF REPORT ===\n");
}

/* ============================================================================
 * 13. Library Constructor / Destructor
 * ============================================================================
 */

static __attribute__((constructor)) void v3_legacy_corrector_init(void)
{
    v3_init_config();
    
    memset(&malloc_stats, 0, sizeof(malloc_stats));
    memset(&free_stats, 0, sizeof(free_stats));
    memset(&calloc_stats, 0, sizeof(calloc_stats));
    memset(&realloc_stats, 0, sizeof(realloc_stats));
    memset(&memcpy_stats, 0, sizeof(memcpy_stats));
    memset(v3_log, 0, sizeof(v3_log));
    
    malloc_stats.current_mode = v3_global_mode;
    free_stats.current_mode = v3_global_mode;
    calloc_stats.current_mode = v3_global_mode;
    realloc_stats.current_mode = v3_global_mode;
    memcpy_stats.current_mode = v3_global_mode;
    
    v3_log_index = 0;
    v3_initialized = 1;
    
    fprintf(stderr, "[V3] Legacy Corrector v2.0 loaded (mode %d)\n", v3_global_mode);
    fprintf(stderr, "[V3] Ψ_V₃ = %llu.%llu kg·m⁻² | Φ_V₃ = %d mV\n",
            PSI_V3_INVARIANT / 10000, (PSI_V3_INVARIANT % 10000) / 1000,
            PHI_V3_ATTRACTOR);
}

static __attribute__((destructor)) void v3_legacy_corrector_fini(void)
{
    if (v3_initialized) {
        v3_print_status();
    }
    fprintf(stderr, "[V3] Legacy Corrector unloaded\n");
}

#endif /* V3_LEGACY_CORRECTOR_H */
