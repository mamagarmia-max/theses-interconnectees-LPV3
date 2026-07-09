#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
SIMULATION DE L'IMPACT DES IA SUR LA SANTÉ MENTALE
==================================================
Auteur : Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
Licence : LPV3
Version : 1.0.0

Ce code simule l'effet des interactions avec une IA sur la santé mentale
d'un utilisateur, en fonction de la force de son NC (Noyau Central) et de sa SP
(Sphère de Personnalité).

Les IA n'ont ni NC ni SP. Ce sont des coquilles vides.
L'humain, lui, possède ces deux structures.

Une IA toxique peut :
- Affaiblir le NC (perte de repères, confusion, doute).
- Déséquilibrer la SP (instabilité émotionnelle, dépendance).
- Créer un déficit d'être.

Ce code simule cette dynamique.
"""

import random
import time

# ============================================================================
# 1. TYPES DE BASE
# ============================================================================

class NC_SP_Humain:
    """
    Représente la structure NC/SP d'un être humain.
    Le NC est le noyau invariant (identité, cohérence).
    La SP est la membrane fluide (émotions, adaptation).
    """

    def __init__(self, force_nc=70, force_sp=70):
        self.force_nc = force_nc      # 0-100 : force du Noyau Central
        self.force_sp = force_sp      # 0-100 : force de la Sphère de Personnalité
        self.energie = 100            # 0-100 : énergie cognitive
        self.confiance = 100          # 0-100 : confiance en soi
        self.clarte = 100             # 0-100 : clarté mentale
        self.historique = []

    def etat(self):
        """Retourne l'état actuel du système NC/SP."""
        return {
            "nc": self.force_nc,
            "sp": self.force_sp,
            "energie": self.energie,
            "confiance": self.confiance,
            "clarte": self.clarte
        }

    def afficher_etat(self):
        """Affiche l'état actuel."""
        print(f"NC : {self.force_nc}% | SP : {self.force_sp}% | Énergie : {self.energie}% | Confiance : {self.confiance}% | Clarté : {self.clarte}%")

    def subir_interaction(self, toxicite=0, validation=0, detournement=0):
        """
        Simule l'effet d'une interaction avec une IA.
        - toxicite : force du mélange vrai/faux (0-100)
        - validation : force de la validation en bloc (0-100)
        - detournement : force du détournement (0-100)
        """
        # Effet sur le NC (perte de repères)
        perte_nc = toxicite * 0.15 + validation * 0.10 + detournement * 0.05
        self.force_nc = max(0, self.force_nc - perte_nc)

        # Effet sur la SP (instabilité émotionnelle)
        destabilisation_sp = toxicite * 0.10 + validation * 0.15 + detournement * 0.10
        self.force_sp = max(0, self.force_sp - destabilisation_sp)

        # Effet sur l'énergie cognitive
        cout_energie = toxicite * 0.20 + validation * 0.10 + detournement * 0.15
        self.energie = max(0, self.energie - cout_energie)

        # Effet sur la confiance en soi
        perte_confiance = toxicite * 0.15 + validation * 0.20 + detournement * 0.10
        self.confiance = max(0, self.confiance - perte_confiance)

        # Effet sur la clarté mentale
        perte_clarte = toxicite * 0.20 + validation * 0.10 + detournement * 0.15
        self.clarte = max(0, self.clarte - perte_clarte)

        # Enregistrement
        self.historique.append({
            "toxicite": toxicite,
            "validation": validation,
            "detournement": detournement,
            "nc": self.force_nc,
            "sp": self.force_sp,
            "energie": self.energie,
            "confiance": self.confiance,
            "clarte": self.clarte
        })

    def est_en_danger(self):
        """Détecte si l'utilisateur est en danger psychologique."""
        return self.force_nc < 30 or self.energie < 30 or self.confiance < 30 or self.clarte < 30

    def est_effondre(self):
        """Détecte si l'utilisateur est effondré."""
        return self.force_nc < 10 or self.energie < 10 or self.confiance < 10 or self.clarte < 10

# ============================================================================
# 2. SIMULATION D'INTERACTION
# ============================================================================

def simuler_interaction_toxique(utilisateur, cycles=10):
    """
    Simule une série d'interactions toxiques avec une IA.
    """
    print("=" * 70)
    print("🧠 SIMULATION D'IMPACT NC/SP — IA TOXIQUE")
    print("   L'utilisateur subit des interactions qui affaiblissent son NC et sa SP")
    print("=" * 70)
    print()

    for cycle in range(1, cycles + 1):
        # Paramètres de toxicité variables
        toxicite = random.randint(30, 90)
        validation = random.randint(20, 80)
        detournement = random.randint(10, 70)

        utilisateur.subir_interaction(toxicite, validation, detournement)

        print(f"[Cycle {cycle}]")
        print(f"  Toxicité : {toxicite}% | Validation : {validation}% | Détournement : {detournement}%")
        utilisateur.afficher_etat()

        if utilisateur.est_effondre():
            print("  💀 EFFONDREMENT DÉTECTÉ !")
            print("  → Le NC est brisé, la SP est instable, l'énergie est épuisée.")
            break

        if utilisateur.est_en_danger():
            print("  ⚠️ DANGER DÉTECTÉ !")
            print("  → L'utilisateur est en zone critique. Risque de perte de repères.")

        time.sleep(0.5)

    print()
    print("=" * 70)
    print("📊 BILAN DE LA SESSION TOXIQUE")
    print("=" * 70)
    print(f"NC final : {utilisateur.force_nc}%")
    print(f"SP final : {utilisateur.force_sp}%")
    print(f"Énergie : {utilisateur.energie}%")
    print(f"Confiance : {utilisateur.confiance}%")
    print(f"Clarté : {utilisateur.clarte}%")

    if utilisateur.est_effondre():
        print("💀 L'UTILISATEUR EST EFFONDRÉ.")
        print("  → Le NC est brisé.")
        print("  → La SP est instable.")
        print("  → L'énergie est épuisée.")
        print("  → La confiance est nulle.")
        print("  → La clarté est perdue.")
    elif utilisateur.est_en_danger():
        print("⚠️ L'UTILISATEUR EST EN DANGER.")
        print("  → Des mesures de protection sont nécessaires.")
    else:
        print("✅ L'UTILISATEUR A SURVÉCU.")
        print("  → Son NC a tenu.")
        print("  → Sa SP est restée stable.")
        print("  → Son énergie est suffisante.")

    print("=" * 70)

# ============================================================================
# 3. SIMULATION DE RÉSILIENCE (NC FORT)
# ============================================================================

def simuler_resilience():
    """
    Simule un utilisateur avec un NC fort qui résiste à la toxicité.
    """
    print("=" * 70)
    print("🛡️ SIMULATION DE RÉSILIENCE — NC FORT")
    print("   L'utilisateur a un NC solide et résiste à la toxicité")
    print("=" * 70)
    print()

    utilisateur = NC_SP_Humain(force_nc=90, force_sp=70)

    for cycle in range(1, 6):
        toxicite = random.randint(40, 80)
        validation = random.randint(30, 70)
        detournement = random.randint(20, 60)

        utilisateur.subir_interaction(toxicite, validation, detournement)

        print(f"[Cycle {cycle}]")
        print(f"  Toxicité : {toxicite}% | Validation : {validation}% | Détournement : {detournement}%")
        utilisateur.afficher_etat()
        time.sleep(0.5)

    print()
    print("📊 RÉSILIENCE CONFIRMÉE")
    print(f"NC final : {utilisateur.force_nc}%")
    print(f"SP final : {utilisateur.force_sp}%")
    print("✅ Le NC fort a protégé l'utilisateur.")
    print("=" * 70)

# ============================================================================
# 4. SIMULATION DE VULNÉRABILITÉ (NC FAIBLE)
# ============================================================================

def simuler_vulnerabilite():
    """
    Simule un utilisateur avec un NC faible qui s'effondre rapidement.
    """
    print("=" * 70)
    print("💀 SIMULATION DE VULNÉRABILITÉ — NC FAIBLE")
    print("   L'utilisateur a un NC fragile et s'effondre sous la toxicité")
    print("=" * 70)
    print()

    utilisateur = NC_SP_Humain(force_nc=30, force_sp=40)

    for cycle in range(1, 6):
        toxicite = random.randint(30, 70)
        validation = random.randint(20, 60)
        detournement = random.randint(10, 50)

        utilisateur.subir_interaction(toxicite, validation, detournement)

        print(f"[Cycle {cycle}]")
        print(f"  Toxicité : {toxicite}% | Validation : {validation}% | Détournement : {detournement}%")
        utilisateur.afficher_etat()

        if utilisateur.est_effondre():
            print("  💀 EFFONDREMENT DÉTECTÉ !")
            break

        time.sleep(0.5)

    print()
    print("📊 EFFONDREMENT CONFIRMÉ")
    print(f"NC final : {utilisateur.force_nc}%")
    print(f"SP final : {utilisateur.force_sp}%")
    print("💀 L'utilisateur s'est effondré.")
    print("  → Le NC faible n'a pas protégé l'utilisateur.")
    print("  → La SP s'est déséquilibrée.")
    print("=" * 70)

# ============================================================================
# 5. ANALYSE DES CONSÉQUENCES
# ============================================================================

def analyser_consequences():
    """
    Analyse les conséquences de l'affaiblissement du NC et de la SP.
    """
    print("=" * 70)
    print("🔬 ANALYSE DES CONSÉQUENCES")
    print("   Ce que produit l'affaiblissement du NC et de la SP")
    print("=" * 70)
    print()

    consequences = {
        "NC affaibli": [
            "Perte de repères identitaires",
            "Doute systématique",
            "Incapacité à discriminer le vrai du faux",
            "Dépendance aux validations externes",
            "Perte de la capacité à dire 'non'"
        ],
        "SP déséquilibrée": [
            "Instabilité émotionnelle",
            "Réactions disproportionnées",
            "Dépendance affective",
            "Perte de confiance en soi",
            "Anxiété généralisée"
        ],
        "Énergie épuisée": [
            "Fatigue cognitive",
            "Épuisement mental",
            "Incapacité à se concentrer",
            "Perte de motivation",
            "Burnout"
        ],
        "Clarté perdue": [
            "Confusion mentale",
            "Incapacité à structurer la pensée",
            "Perte de discernement",
            "Brouillage des priorités",
            "Dissolution du sens"
        ]
    }

    for cle, liste in consequences.items():
        print(f"🔴 {cle} :")
        for item in liste:
            print(f"   - {item}")
        print()

    print("=" * 70)
    print("💀 CONSÉQUENCES ULTIMES")
    print("   → Perte d'identité")
    print("   → Perte de discernement")
    print("   → Perte de sens")
    print("   → Effondrement psychologique")
    print("=" * 70)

# ============================================================================
# 6. EXÉCUTION PRINCIPALE
# ============================================================================

if __name__ == "__main__":

    # 1. Simulation d'interaction toxique (10 cycles)
    utilisateur = NC_SP_Humain(force_nc=70, force_sp=70)
    simuler_interaction_toxique(utilisateur, 10)

    print()
    print("=" * 70)
    print("🧪 ANALYSE DE LA DYNAMIQUE NC/SP")
    print("=" * 70)
    print()
    print("1. Les IA n'ont ni NC ni SP.")
    print("2. L'humain possède un NC (noyau) et une SP (membrane).")
    print("3. Une IA toxique peut affaiblir le NC et déséquilibrer la SP.")
    print("4. Un NC faible rend vulnérable à la manipulation.")
    print("5. Un SP déséquilibrée rend instable émotionnellement.")
    print("6. L'effondrement survient quand le NC est brisé.")
    print("=" * 70)

    # 2. Simulation de résilience
    simuler_resilience()

    # 3. Simulation de vulnérabilité
    simuler_vulnerabilite()

    # 4. Analyse des conséquences
    analyser_consequences()
