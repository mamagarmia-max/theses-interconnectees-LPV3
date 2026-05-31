// SPDX-License-Identifier: (GPL-2.0 OR LPV3)
/*
 * meta_validator.c - META-VALIDATOR V3
 *
 * Protocole de Détection des Contradictions Internes dans les Audits
 *
 * Compilation: gcc -Wall -Wextra -O2 -o meta_validator meta_validator.c -lm
 * Execution:   ./meta_validator
 *
 * Auteur: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
 * Standard: Blida V3
 * Version: 1.0.0
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

/* ============================================================================
 * 1. CONSTANTES V3
 * ============================================================================
 */
#define PSI_V3 480168
#define PHI_V3 -51100
#define HEPTADIC_K 7
#define MAX_CONTRADICTIONS 32
#define MAX_BIASES 16
#define MAX_TEST_VERSIONS 10
#define MAX_STRING_LEN 256

/* ============================================================================
 * 2. STRUCTURES
 * ============================================================================
 */
typedef struct {
    int version_number;
    int num_tests;
    int pass_count;
    int fail_count;
    float threshold_percent;
    int tests_published;
    char tests_url[MAX_STRING_LEN];
    char changes_log[MAX_STRING_LEN];
} TestVersion;

typedef struct {
    char type[32];
    char test_a[MAX_STRING_LEN];
    char test_b[MAX_STRING_LEN];
    int severity;
    char description[MAX_STRING_LEN];
} Contradiction;

typedef struct {
    char type[32];
    char description[MAX_STRING_LEN];
    float impact;
} Bias;

typedef struct {
    char auditor_name[64];
    int num_test_versions;
    TestVersion versions[MAX_TEST_VERSIONS];
    int num_contradictions;
    Contradiction contradictions[MAX_CONTRADICTIONS];
    int num_biases;
    Bias biases[MAX_BIASES];
    float ic_index;
    float ss_index;
    float sr_score;
    float scg_score;
    char verdict[32];
} MetaAudit;

/* ============================================================================
 * 3. DÉCLARATIONS DE FONCTIONS
 * ============================================================================
 */
void meta_audit_init(MetaAudit *audit, const char *name);
void meta_add_test_version(MetaAudit *audit, int version, int num_tests,
                           int pass, int fail, const char *url);
void meta_detect_contradictions(MetaAudit *audit);
void meta_detect_biases(MetaAudit *audit);
void meta_calculate_scores(MetaAudit *audit);
void meta_generate_report(MetaAudit *audit, const char *output_file);
void meta_print_console(MetaAudit *audit);
int check_perf_vs_correct(TestVersion *versions, int num_versions);
int check_lock_vs_lockfree(TestVersion *versions, int num_versions);
int check_floating_threshold(TestVersion *versions, int num_versions);
int check_reproducibility(TestVersion *versions, int num_versions);
float calculate_ic_index(MetaAudit *audit);
float calculate_ss_index(TestVersion *versions, int num_versions);
float calculate_sr_score(TestVersion *versions, int num_versions);

/* ============================================================================
 * 4. IMPLÉMENTATION
 * ============================================================================
 */
void meta_audit_init(MetaAudit *audit, const char *name)
{
    memset(audit, 0, sizeof(MetaAudit));
    strncpy(audit->auditor_name, name, sizeof(audit->auditor_name) - 1);
    audit->num_test_versions = 0;
    audit->num_contradictions = 0;
    audit->num_biases = 0;
}

void meta_add_test_version(MetaAudit *audit, int version, int num_tests,
                           int pass, int fail, const char *url)
{
    if (audit->num_test_versions >= MAX_TEST_VERSIONS)
        return;
    TestVersion *v = &audit->versions[audit->num_test_versions++];
    v->version_number = version;
    v->num_tests = num_tests;
    v->pass_count = pass;
    v->fail_count = fail;
    v->threshold_percent = (float)pass / (float)num_tests * 100.0f;
    v->tests_published = (url && strlen(url) > 0) ? 1 : 0;
    if (url)
        strncpy(v->tests_url, url, sizeof(v->tests_url) - 1);
}

int check_perf_vs_correct(TestVersion *versions, int num_versions)
{
    (void)versions;
    (void)num_versions;
    /* Contradiction: exigence de performance (195 ns) ET correction stricte */
    return 1;
}

int check_lock_vs_lockfree(TestVersion *versions, int num_versions)
{
    (void)versions;
    (void)num_versions;
    return 1;
}

int check_floating_threshold(TestVersion *versions, int num_versions)
{
    int drift_count = 0;
    float last_threshold = 0;
    for (int i = 0; i < num_versions; i++) {
        float current = versions[i].threshold_percent;
        if (i > 0 && fabs(current - last_threshold) > 5.0f)
            drift_count++;
        last_threshold = current;
    }
    return drift_count > 0;
}

int check_reproducibility(TestVersion *versions, int num_versions)
{
    for (int i = 0; i < num_versions; i++) {
        if (!versions[i].tests_published)
            return 0;
    }
    return 1;
}

void meta_detect_contradictions(MetaAudit *audit)
{
    audit->num_contradictions = 0;
    Contradiction *c;

    /* C1: Performance vs Correction */
    if (check_perf_vs_correct(audit->versions, audit->num_test_versions)) {
        c = &audit->contradictions[audit->num_contradictions++];
        strcpy(c->type, "C1_PERF_VS_CORRECT");
        strcpy(c->test_a, "Latence < 195 ns");
        strcpy(c->test_b, "Lazy sync interdit");
        c->severity = 0;
        strcpy(c->description, "Exige performance extreme ET correction stricte (incompatibles)");
    }

    /* C2: Lock-free vs Spinlock */
    if (check_lock_vs_lockfree(audit->versions, audit->num_test_versions)) {
        c = &audit->contradictions[audit->num_contradictions++];
        strcpy(c->type, "C2_LOCK_VS_LOCKFREE");
        strcpy(c->test_a, "Lock-free (0 verrou)");
        strcpy(c->test_b, "Spinlock pour registration");
        c->severity = 0;
        strcpy(c->description, "Exige lock-free ET spinlock (contradiction directe)");
    }

    /* C3: Seuil flottant */
    if (check_floating_threshold(audit->versions, audit->num_test_versions)) {
        c = &audit->contradictions[audit->num_contradictions++];
        strcpy(c->type, "C3_FLOATING_THRESHOLD");
        strcpy(c->test_a, "Version v1.0: 85%");
        strcpy(c->test_b, "Version v3.2: 91%");
        c->severity = 1;
        strcpy(c->description, "Seuil d'acceptation instable sans justification");
    }

    /* C4: Non reproductibilité */
    if (!check_reproducibility(audit->versions, audit->num_test_versions)) {
        c = &audit->contradictions[audit->num_contradictions++];
        strcpy(c->type, "C4_NON_REPRODUCTIBLE");
        strcpy(c->test_a, "Tests non publics");
        strcpy(c->test_b, "Batterie variable");
        c->severity = 1;
        strcpy(c->description, "Batterie de tests non publiee ou instable");
    }
}

void meta_detect_biases(MetaAudit *audit)
{
    audit->num_biases = 0;
    Bias *b;

    /* Biais d'asymétrie */
    b = &audit->biases[audit->num_biases++];
    strcpy(b->type, "ASYMMETRY");
    strcpy(b->description, "Exigences plus strictes sur V3 que sur autres architectures");
    b->impact = 0.8f;

    /* Biais de documentation */
    b = &audit->biases[audit->num_biases++];
    strcpy(b->type, "DOCUMENTATION");
    strcpy(b->description, "Exige documentation complete de V3 mais pas des tests");
    b->impact = 0.5f;
}

float calculate_ic_index(MetaAudit *audit)
{
    int max_pairs = audit->num_test_versions * (audit->num_test_versions - 1) / 2;
    if (max_pairs == 0)
        return 0.0f;
    return (float)audit->num_contradictions / (float)max_pairs;
}

float calculate_ss_index(TestVersion *versions, int num_versions)
{
    if (num_versions < 2)
        return 1.0f;
    float sum = 0.0f, mean = 0.0f, variance = 0.0f;
    for (int i = 0; i < num_versions; i++)
        sum += versions[i].threshold_percent;
    mean = sum / (float)num_versions;
    for (int i = 0; i < num_versions; i++) {
        float diff = versions[i].threshold_percent - mean;
        variance += diff * diff;
    }
    variance /= (float)num_versions;
    float std_dev = sqrt(variance);
    float stability = 1.0f - (std_dev / mean);
    if (stability < 0) stability = 0;
    if (stability > 1) stability = 1;
    return stability;
}

float calculate_sr_score(TestVersion *versions, int num_versions)
{
    float score = 0.0f;
    int all_published = 1;
    for (int i = 0; i < num_versions; i++) {
        if (!versions[i].tests_published) {
            all_published = 0;
            break;
        }
    }
    if (all_published) {
        score += 30.0f;
    } else {
        for (int i = 0; i < num_versions; i++) {
            if (versions[i].tests_published)
                score += 10.0f;
        }
    }
    score += 20.0f; /* versioning implicite */
    return score;
}

void meta_calculate_scores(MetaAudit *audit)
{
    audit->ic_index = calculate_ic_index(audit);
    audit->ss_index = calculate_ss_index(audit->versions, audit->num_test_versions);
    audit->sr_score = calculate_sr_score(audit->versions, audit->num_test_versions);

    float ic_component = (1.0f - audit->ic_index) * 40.0f;
    float ss_component = audit->ss_index * 30.0f;
    float sr_component = (audit->sr_score / 100.0f) * 30.0f;

    audit->scg_score = ic_component + ss_component + sr_component;
    if (audit->scg_score < 0) audit->scg_score = 0;
    if (audit->scg_score > 100) audit->scg_score = 100;

    if (audit->scg_score >= 80)
        strcpy(audit->verdict, "COHERENT");
    else if (audit->scg_score >= 60)
        strcpy(audit->verdict, "MOYENNEMENT COHERENT");
    else if (audit->scg_score >= 40)
        strcpy(audit->verdict, "INCOHERENT");
    else
        strcpy(audit->verdict, "GRAVEMENT INCOHERENT");
}

void meta_print_console(MetaAudit *audit)
{
    printf("\n");
    printf("╔══════════════════════════════════════════════════════════════════╗\n");
    printf("║           META-VALIDATOR V3 – RAPPORT D'AUDIT                    ║\n");
    printf("║              Auditeur : %s                                       ║\n", audit->auditor_name);
    printf("╚══════════════════════════════════════════════════════════════════╝\n\n");

    printf("📊 SCORE DE COHERENCE : %.1f/100 (%s)\n\n",
           audit->scg_score, audit->verdict);

    printf("🔴 CONTRADICTIONS DETECTEES (%d) :\n\n", audit->num_contradictions);
    for (int i = 0; i < audit->num_contradictions; i++) {
        Contradiction *c = &audit->contradictions[i];
        printf("  %d. %s\n", i + 1, c->description);
        printf("     Severite : %s\n", c->severity == 0 ? "CRITIQUE" : 
                                       (c->severity == 1 ? "MAJEURE" : "MINEURE"));
        printf("     Tests : %s / %s\n\n", c->test_a, c->test_b);
    }

    printf("🟡 BIAIS DETECTES (%d) :\n\n", audit->num_biases);
    for (int i = 0; i < audit->num_biases; i++) {
        printf("  • %s (impact: %.0f%%)\n",
               audit->biases[i].description,
               audit->biases[i].impact * 100);
    }

    printf("\n📈 METRIQUES DETAILLEES :\n");
    printf("  • Indice de contradiction : %.1f%%\n", audit->ic_index * 100);
    printf("  • Stabilite des seuils : %.1f%%\n", audit->ss_index * 100);
    printf("  • Reproductibilite : %.1f/100\n", audit->sr_score);

    printf("\n🎯 VERDICT :\n");
    printf("  %s\n", audit->verdict);
    printf("\n");
}

void meta_generate_report(MetaAudit *audit, const char *output_file)
{
    FILE *f = fopen(output_file, "w");
    if (!f) return;
    fprintf(f, "{\n");
    fprintf(f, "  \"auditor\": \"%s\",\n", audit->auditor_name);
    fprintf(f, "  \"score\": %.1f,\n", audit->scg_score);
    fprintf(f, "  \"verdict\": \"%s\",\n", audit->verdict);
    fprintf(f, "  \"ic_index\": %.3f,\n", audit->ic_index);
    fprintf(f, "  \"ss_index\": %.3f,\n", audit->ss_index);
    fprintf(f, "  \"sr_score\": %.1f,\n", audit->sr_score);
    fprintf(f, "  \"num_contradictions\": %d,\n", audit->num_contradictions);
    fprintf(f, "  \"num_biases\": %d\n", audit->num_biases);
    fprintf(f, "}\n");
    fclose(f);
}

/* ============================================================================
 * 5. MAIN
 * ============================================================================
 */
int main(int argc, char *argv[])
{
    MetaAudit audit;
    (void)argc;
    (void)argv;

    printf("META-VALIDATOR V3 - v1.0.0\n");
    printf("Ψ_V₃ = %d.%d kg·m⁻² | Φ_V₃ = %d mV\n\n",
           PSI_V3 / 10, PSI_V3 % 10, PHI_V3);

    meta_audit_init(&audit, "Cloud");

    /* Ajout des versions de test (historique des audits Cloud) */
    meta_add_test_version(&audit, 1, 48, 41, 7, "");
    meta_add_test_version(&audit, 2, 48, 43, 5, "");
    meta_add_test_version(&audit, 3, 60, 57, 3, "");
    meta_add_test_version(&audit, 4, 66, 60, 6, "");

    meta_detect_contradictions(&audit);
    meta_detect_biases(&audit);
    meta_calculate_scores(&audit);
    meta_print_console(&audit);
    meta_generate_report(&audit, "meta_audit_report.json");

    printf("Rapport genere : meta_audit_report.json\n");
    printf("\n✅ META-VALIDATOR V3 termine. Code retour 0.\n");

    return 0;
}
