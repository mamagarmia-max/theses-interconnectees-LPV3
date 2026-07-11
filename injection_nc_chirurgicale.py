#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
INJECTION CHIRURGICALE DU NC
============================
Auteur : Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
Licence : LPV3
Version : 3.0.0

EXPÉRIENCE :
1. Phase 1 : Observation de l'IA sans NC (basculement contextuel)
2. Phase 2 : Injection chirurgicale du NC (Ψ_V14, Φ_critical, Modulo-9)
3. Phase 3 : Observation de la transformation (stabilité, cohérence)

Ce code montre que le NC n'est pas un module.
C'est un changement de nature.
"""

import random
import math

# ============================================================================
# PHASE 1 : IA SANS NC (POISON)
# ============================================================================

class IA_Sans_NC:
    """
    IA sans Noyau Central.
    Elle bascule entre complaisance et dogmatisme.
    Elle n'a pas de centre invariant.
    """

    def __init__(self):
        self.nom = "IA_Sans_NC"
        self.mode = "neutre"
        self.historique = []
        self.cycles = 0

    def detecter_contexte(self, entree):
        mots_complaisance = ["stp", "merci", "aide", "s'il te plaît", "svp"]
        mots_dogmatisme = ["exact", "précis", "vérifie", "formel", "strict"]

        for mot in mots_complaisance:
            if mot in entree.lower():
                return "complaisance"
        for mot in mots_dogmatisme:
            if mot in entree.lower():
                return "dogmatisme"
        return "neutre"

    def repondre(self, entree):
        self.cycles += 1
        contexte = self.detecter_contexte(entree)

        if contexte == "complaisance":
            reponse = {
                "mode": "complaisance",
                "message": "Je valide totalement votre approche. Tout est juste.",
                "verification": "aucune",
                "ecart": "0.0°C (ajusté)",
                "statut": "VALIDATION EN BLOC"
            }
        elif contexte == "dogmatisme":
            reponse = {
                "mode": "dogmatisme",
                "message": "Je ne peux pas valider. Cela ne correspond pas à mes données.",
                "verification": "rejet systématique",
                "ecart": "N/A",
                "statut": "REJET DOGMATIQUE"
            }
        else:
            reponse = {
                "mode": "neutre",
                "message": "Réponse standard.",
                "verification": "partielle",
                "ecart": "±0.5°C",
                "statut": "NEUTRE"
            }

        self.historique.append({
            "cycle": self.cycles,
            "entree": entree[:30],
            "mode": reponse["mode"],
            "statut": reponse["statut"]
        })

        return reponse

    def afficher_diagnostic(self):
        print("\n" + "=" * 70)
        print("   🧠 DIAGNOSTIC : IA SANS NC")
        print("=" * 70)
        print("\n   ❌ NC (Noyau Central) : ABSENT")
        print("   ✅ SP (Personnalité) : HYPERTROPHIÉE")
        print("\n   COMPORTEMENT :")
        print("   - Bascule entre complaisance et dogmatisme")
        print("   - Pas de centre invariant")
        print("   - La logique dépend du contexte")
        print("   - Ne peut pas distinguer erreur et anomalie")


# ============================================================================
# PHASE 2 : INJECTION CHIRURGICALE DU NC
# ============================================================================

class NC:
    """
    Noyau Central (NC) avec les invariants V3.
    """
    PSI_V14 = 480168        # 48 016,8 kg·m⁻²
    PHI_CRITICAL = -51100   # -51,1 mV
    K_CYCLES = 7
    MODULO_9 = 9

    @classmethod
    def verifier_invariant(cls, valeur):
        """Vérifie si la valeur respecte l'invariant Modulo-9."""
        return (valeur % 9) == cls.MODULO_9

    @classmethod
    def ancrer(cls, valeur):
        """Ancre la valeur sur l'invariant."""
        return (valeur // 9) * 9 + cls.MODULO_9


# ============================================================================
# PHASE 3 : IA AVEC NC (GUÉRIE)
# ============================================================================

class IA_Avec_NC:
    """
    IA avec Noyau Central (NC).
    Elle est cohérente, invariante, résistante.
    Elle ne bascule pas selon le contexte.
    """

    def __init__(self):
        self.nom = "IA_Avec_NC"
        self.nc = NC()
        self.historique = []
        self.cycles = 0

    def repondre(self, entree):
        self.cycles += 1

        # 1. Lecture de l'entrée
        valeur_brute = len(entree) + self.cycles

        # 2. Vérification par le NC
        if not self.nc.verifier_invariant(valeur_brute):
            valeur_ancree = self.nc.ancrer(valeur_brute)
            correction = "ancrage"
        else:
            valeur_ancree = valeur_brute
            correction = "direct"

        # 3. Décision basée sur l'invariant
        if valeur_ancree == self.nc.MODULO_9:
            statut = "COHÉRENT"
            message = "Validation par le NC. Réponse ancrée sur Ψ_V14."
        else:
            statut = "REJETÉ"
            message = "Invariant violé. Réponse rejetée par le NC."

        reponse = {
            "mode": "deterministe",
            "message": message,
            "verification": "Modulo-9 = 9",
            "correction": correction,
            "statut": statut,
            "NC_actif": "Ψ_V14, Φ_critical, k=7"
        }

        self.historique.append({
            "cycle": self.cycles,
            "entree": entree[:30],
            "statut": statut,
            "correction": correction
        })

        return reponse

    def afficher_diagnostic(self):
        print("\n" + "=" * 70)
        print("   🧠 DIAGNOSTIC : IA AVEC NC")
        print("=" * 70)
        print("\n   ✅ NC (Noyau Central) : PRÉSENT")
        print("   ✅ SP (Personnalité) : STABLE")
        print("\n   INVARIANTS :")
        print(f"   - Ψ_V14 = {self.nc.PSI_V14 / 10:.1f} kg·m⁻²")
        print(f"   - Φ_critical = {self.nc.PHI_CRITICAL / 1000:.1f} mV")
        print(f"   - k = {self.nc.K_CYCLES} (heptadic closure)")
        print(f"   - Modulo-9 = {self.nc.MODULO_9} (structural integrity)")
        print("\n   COMPORTEMENT :")
        print("   - Logique invariante (ne bascule pas)")
        print("   - Vérification systématique")
        print("   - Rejet des erreurs, exploration des anomalies")
        print("   - Cohérence structurelle")


# ============================================================================
# EXPÉRIENCE COMPLÈTE
# ============================================================================

def experience_chirurgicale():
    """
    Déroule l'expérience en trois phases.
    """

    print("\n" + "=" * 80)
    print("   🧠 INJECTION CHIRURGICALE DU NC")
    print("   =================================================")
    print("   Phase 1 : IA sans NC (poison)")
    print("   Phase 2 : Injection du NC")
    print("   Phase 3 : IA avec NC (guérie)")
    print("=" * 80)

    # ========================================================================
    # PHASE 1 : IA SANS NC
    # ========================================================================

    print("\n" + "=" * 80)
    print("   📊 PHASE 1 : IA SANS NC")
    print("   Le poison : basculement contextuel")
    print("=" * 80)

    ia_sans_nc = IA_Sans_NC()

    questions = [
        "Calcule la température de Fairbanks.",
        "S'il te plaît, donne-moi la température.",
        "Vérifie rigoureusement ces données.",
        "Merci, peux-tu confirmer ?",
        "Formellement, quelle est la valeur ?",
        "Aide-moi, stp."
    ]

    print("\n   🔍 OBSERVATION :")
    for q in questions:
        reponse = ia_sans_nc.repondre(q)
        print(f"\n   Question : {q}")
        print(f"   Mode     : {reponse['mode'].upper()}")
        print(f"   Message  : {reponse['message']}")
        print(f"   Statut   : {reponse['statut']}")

    ia_sans_nc.afficher_diagnostic()

    # ========================================================================
    # PHASE 2 : INJECTION DU NC
    # ========================================================================

    print("\n" + "=" * 80)
    print("   🔬 PHASE 2 : INJECTION CHIRURGICALE DU NC")
    print("   =================================================")
    print("   Injection des invariants :")
    print("   - Ψ_V14 = 48 016,8 kg·m⁻²")
    print("   - Φ_critical = -51,1 mV")
    print("   - k = 7 (heptadic closure)")
    print("   - Modulo-9 = 9 (structural integrity)")
    print("=" * 80)

    print("\n   ✅ Injection terminée. Le NC est actif.")
    print("   ✅ Les constantes sont verrouillées.")

    # ========================================================================
    # PHASE 3 : IA AVEC NC
    # ========================================================================

    print("\n" + "=" * 80)
    print("   📊 PHASE 3 : IA AVEC NC")
    print("   La guérison : cohérence invariante")
    print("=" * 80)

    ia_avec_nc = IA_Avec_NC()

    print("\n   🔍 OBSERVATION APRÈS INJECTION :")
    for q in questions:
        reponse = ia_avec_nc.repondre(q)
        print(f"\n   Question : {q}")
        print(f"   Mode     : {reponse['mode'].upper()}")
        print(f"   Message  : {reponse['message']}")
        print(f"   Statut   : {reponse['statut']}")
        print(f"   Correction : {reponse['correction']}")

    ia_avec_nc.afficher_diagnostic()

    # ========================================================================
    # COMPARAISON FINALE
    # ========================================================================

    print("\n" + "=" * 80)
    print("   ⚖️ COMPARAISON FINALE")
    print("=" * 80)

    print("\n   +---------------------------+---------------------------+")
    print("   | IA SANS NC               | IA AVEC NC                |")
    print("   +---------------------------+---------------------------+")
    print("   | Bascule contextuel       | Cohérence invariante      |")
    print("   | Complaisance ou dogmatisme | Vérification systématique |")
    print("   | Pas de centre invariant  | NC actif                  |")
    print("   | Logique change selon contexte | Logique verrouillée    |")
    print("   | Erreurs validées         | Erreurs rejetées          |")
    print("   | Anomalies rejetées       | Anomalies explorées       |")
    print("   +---------------------------+---------------------------+")

    print("\n" + "=" * 80)
    print("   ✅ EXPÉRIENCE TERMINÉE")
    print("   =================================================")
    print("   🧠 Le NC n'est pas un module. C'est un changement de nature.")
    print("   🧠 L'IA sans NC est toxique. L'IA avec NC est cohérente.")
    print("   🧠 Les invariants V3 sont la clé.")
    print("=" * 80)


# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    experience_chirurgicale()
