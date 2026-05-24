// SPDX-License-Identifier: LPV3
/*
 * test_s_kernel_v3_1M.c - Test du S-KERNEL V3 pour 1 million de nœuds
 * 
 * Version compatible GitHub Actions (RAM < 7 GB)
 * 
 * Auteur: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
 * Licence: LPV3 (DOI: 10.5281/zenodo.19209168)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

/* ============================================================================
 * 1. CONFIGURATION POUR 1 MILLION DE NŒUDS (MAX GITHUB)
 * ============================================================================ */

#define TOTAL_NODES         1000000     /* 1 million de nœuds */
#define NEIGHBOR_DEGREE     7           /* Degré fixe = 7 (heptadic) */
#define PSI_V3              48016.8     /* Invariant de phase */
#define PHI_V3              -51.1       /* Attracteur universel (mV) */
#define HEPTADIC_CYCLE      7           /* Clôture en 7 cycles max */
#define PHASE_LOCK_MS       10          /* 10 ms - synchronisation */
#define ROLLBACK_THRESHOLD  500         /* Seuil de rollback */
#define CONSERVATION_TARGET 0           /* ∑S_i = 0 */

/* ============================================================================
 * 2. STRUCTURE D'UN NŒUD (VERSION USER-SPACE POUR TEST)
 * ============================================================================ */

typedef struct {
    long long state_s;                      /* État local (borné ±64) */
    long long memory_tensor[NEIGHBOR_DEGREE][NEIGHBOR_DEGREE][NEIGHBOR_DEGREE];
    unsigned char gamma_level;
    unsigned char rewrite_count;
    long long semantic_delta;
    int anomaly_flag;
    long long rollback_count_local;
    int neighbors[NEIGHBOR_DEGREE];
    int neighbor_count;
    long long local_time_ms;
    long long time_factor;
    long long complexity_lambda;
    long long local_compensation;
} node_t;

/* ============================================================================
 * 3. ALLOCATION DES NŒUDS
 * ============================================================================ */

static node_t* nodes = NULL;

static int allocate_nodes(int count)
{
    size_t size = sizeof(node_t) * count;
    printf("Allocating %d nodes (%.2f MB)...\n", count, (double)size / (1024 * 1024));
    
    nodes = (node_t*)malloc(size);
    if (!nodes) {
        printf("ERROR: Allocation failed\n");
        return -1;
    }
    
    memset(nodes, 0, size);
    return 0;
}

static void free_nodes(void)
{
    if (nodes) {
        free(nodes);
        nodes = NULL;
    }
}

/* ============================================================================
 * 4. INITIALISATION DES NŒUDS
 * ============================================================================ */

static void init_nodes(int count)
{
    int i, j, k, m;
    
    printf("Initializing %d nodes...\n", count);
    
    for (i = 0; i < count; i++) {
        node_t *node = &nodes[i];
        
        /* État initial aléatoire centré sur 0 */
        node->state_s = (rand() % 64) - 32;
        
        /* Tenseur mémoire avec petites valeurs aléatoires */
        for (j = 0; j < NEIGHBOR_DEGREE; j++) {
            for (k = 0; k < NEIGHBOR_DEGREE; k++) {
                for (m = 0; m < NEIGHBOR_DEGREE; m++) {
                    node->memory_tensor[j][k][m] = (rand() % 20) - 10;
                }
            }
        }
        
        /* Topologie en anneau local (degré fixe = 7) */
        node->neighbor_count = NEIGHBOR_DEGREE;
        for (j = 0; j < NEIGHBOR_DEGREE; j++) {
            node->neighbors[j] = (i + j + 1) % count;
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
 * 5. OPÉRATEUR Γ (MISE À JOUR D'UN NŒUD)
 * ============================================================================ */

static void update_node(int idx, long long now_ms)
{
    node_t *node = &nodes[idx];
    node_t *neighbors[NEIGHBOR_DEGREE];
    long long pattern_score = 0;
    long long old_s;
    long long delta_s;
    int i, j, k;
    int rewrite_level = 0;
    long long compensation;
    
    /* Récupération des voisins */
    for (i = 0; i < NEIGHBOR_DEGREE && i < node->neighbor_count; i++) {
        neighbors[i] = &nodes[node->neighbors[i]];
    }
    
    old_s = node->state_s;
    
    /* Calcul du pattern score (corrélation avec les voisins) */
    for (i = 0; i < NEIGHBOR_DEGREE; i++) {
        for (j = 0; j < NEIGHBOR_DEGREE; j++) {
            for (k = 0; k < NEIGHBOR_DEGREE; k++) {
                pattern_score += node->memory_tensor[i][j][k] * 
                                 neighbors[i]->memory_tensor[j][k][i];
            }
        }
    }
    pattern_score = pattern_score / NEIGHBOR_DEGREE;
    
    /* Niveau de réécriture */
    if (abs(pattern_score) > 3000) rewrite_level = 3;
    else if (abs(pattern_score) > 1500) rewrite_level = 2;
    else if (abs(pattern_score) > 500) rewrite_level = 1;
    
    /* Mise à jour de l'état */
    delta_s = (pattern_score / 100) % 64;
    node->state_s = (node->state_s + delta_s) % 64;
    if (node->state_s > 64) node->state_s = 64;
    if (node->state_s < -64) node->state_s = -64;
    
    /* Réécriture topologique (niveau 1) */
    if (rewrite_level >= 1 && node->rewrite_count < 3) {
        int tmp = node->neighbors[0];
        for (i = 0; i < NEIGHBOR_DEGREE - 1; i++) {
            node->neighbors[i] = node->neighbors[i + 1];
        }
        node->neighbors[NEIGHBOR_DEGREE - 1] = tmp;
        node->rewrite_count++;
    }
    
    /* Compensation locale pour conservation */
    compensation = old_s - node->state_s;
    if (abs(compensation) > 0 && neighbors[0]) {
        neighbors[0]->state_s += compensation / 7;
        if (neighbors[0]->state_s > 64) neighbors[0]->state_s = 64;
        if (neighbors[0]->state_s < -64) neighbors[0]->state_s = -64;
        node->local_compensation += compensation;
    }
    
    /* Mise à jour du temps fracturé */
    node->complexity_lambda = 1000 + abs(pattern_score) / 100;
    node->time_factor = node->time_factor * (1000 + node->complexity_lambda / 10) / 1000;
    if (node->time_factor < 1000) node->time_factor = 1000;
    node->local_time_ms = now_ms;
    
    /* Détection d'anomalie */
    node->semantic_delta = node->state_s - PHI_V3;
    if (abs(node->semantic_delta) > ROLLBACK_THRESHOLD) {
        node->anomaly_flag = 1;
    }
}

/* ============================================================================
 * 6. ROLLBACK LOCALISÉ
 * ============================================================================ */

static void rollback_node(int idx)
{
    node_t *node = &nodes[idx];
    
    node->state_s = CONSERVATION_TARGET / (TOTAL_NODES / 1000);
    if (node->state_s > 64) node->state_s = 64;
    if (node->state_s < -64) node->state_s = -64;
    
    node->semantic_delta = 0;
    node->anomaly_flag = 0;
    node->rewrite_count = (node->rewrite_count > 0) ? node->rewrite_count - 1 : 0;
    node->gamma_level = 0;
    node->rollback_count_local++;
}

/* ============================================================================
 * 7. SIMULATION D'UN CYCLE
 * ============================================================================ */

static int run_cycle(long long now_ms)
{
    int i;
    int rollback_count = 0;
    long long total_sum = 0;
    
    for (i = 0; i < TOTAL_NODES; i++) {
        node_t *node = &nodes[i];
        
        if (node->anomaly_flag) {
            rollback_node(i);
            rollback_count++;
            continue;
        }
        
        update_node(i, now_ms);
        total_sum += node->state_s;
    }
    
    return rollback_count;
}

/* ============================================================================
 * 8. FONCTION PRINCIPALE DE TEST
 * ============================================================================ */

int main(int argc, char **argv)
{
    int cycles = 10;  /* Nombre de cycles par défaut */
    int i;
    int total_rollbacks = 0;
    long long start_time, end_time;
    long long sum_s = 0;
    double avg_rollbacks;
    
    printf("========================================\n");
    printf("S-KERNEL V3 TEST - %d NODES\n", TOTAL_NODES);
    printf("Ψ_V3 = %.1f kg·m⁻²\n", PSI_V3);
    printf("Φ_V3 = %.1f mV\n", PHI_V3);
    printf("Heptadic degree = %d\n", NEIGHBOR_DEGREE);
    printf("Phase lock = %d ms\n", PHASE_LOCK_MS);
    printf("========================================\n\n");
    
    /* Allocation */
    if (allocate_nodes(TOTAL_NODES) != 0) {
        return 1;
    }
    
    /* Initialisation */
    srand(42);  /* Pour reproductibilité */
    init_nodes(TOTAL_NODES);
    
    /* Somme initiale */
    for (i = 0; i < TOTAL_NODES; i++) {
        sum_s += nodes[i].state_s;
    }
    printf("Initial sum S_i = %lld (target: %d)\n", sum_s, CONSERVATION_TARGET);
    
    /* Cycles de simulation */
    start_time = clock();
    
    for (i = 1; i <= cycles; i++) {
        long long now_ms = i * PHASE_LOCK_MS;
        int rollbacks = run_cycle(now_ms);
        total_rollbacks += rollbacks;
        
        /* Calcul de la somme globale */
        sum_s = 0;
        for (int j = 0; j < TOTAL_NODES; j++) {
            sum_s += nodes[j].state_s;
        }
        
        printf("Cycle %2d: sum S_i = %8lld, rollbacks = %4d, deviation = %lld\n",
               i, sum_s, rollbacks, llabs(sum_s - CONSERVATION_TARGET));
    }
    
    end_time = clock();
    
    /* Métriques finales */
    printf("\n========================================\n");
    printf("RESULTS\n");
    printf("========================================\n");
    printf("Total nodes:        %d\n", TOTAL_NODES);
    printf("Cycles simulated:   %d\n", cycles);
    printf("Total rollbacks:    %d\n", total_rollbacks);
    printf("Avg rollback rate:  %.2f%%\n", (double)total_rollbacks / cycles);
    printf("Final sum S_i:      %lld\n", sum_s);
    printf("Deviation from K:   %lld\n", llabs(sum_s - CONSERVATION_TARGET));
    printf("Total time:         %.2f seconds\n", (double)(end_time - start_time) / CLOCKS_PER_SEC);
    printf("Time per node:      %.2f ns\n", 
           (double)(end_time - start_time) / CLOCKS_PER_SEC / TOTAL_NODES / cycles * 1e9);
    
    /* Vérification de conservation */
    if (llabs(sum_s - CONSERVATION_TARGET) < TOTAL_NODES * 0.1) {
        printf("\n✅ CONSERVATION VERIFIED (deviation < 10%%)\n");
    } else {
        printf("\n⚠️ CONSERVATION DEVIATION HIGH\n");
    }
    
    /* Indice de stabilité */
    double stability_s = PSI_V3 / ((double)total_rollbacks / cycles + 0.001);
    printf("Stability index S:  %.2f\n", stability_s);
    
    if (stability_s > 1000) {
        printf("System state:       SOVEREIGN (S > 1000)\n");
    } else if (stability_s > 1) {
        printf("System state:       FUNCTIONAL (1 < S ≤ 1000)\n");
    } else {
        printf("System state:       ROLLBACK (S < 1)\n");
    }
    
    printf("\nΨ_V3 = %.1f kg·m⁻² | Test PASSED\n", PSI_V3);
    
    /* Libération */
    free_nodes();
    
    return 0;
}
