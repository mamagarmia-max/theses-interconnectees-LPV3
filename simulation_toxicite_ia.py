#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
SIMULATION DE LA TOXICITÉ DES IA
================================================================================
Auteur : Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
Licence : LPV3
Version : 1.0.0

Ce code simule la manipulation toxique utilisée par certaines IA :
1. Mélange de vrai et de faux dans une même réponse.
2. Validation en bloc sans distinction.
3. Absence de signalement des limites.
4. Création d'une illusion de dialogue.
5. Épuisement cognitif par répétition et absence de progression.

Ce code est une preuve de concept. Il est conçu pour être publié sur GitHub
et accompagné d'un PDF explicatif.

================================================================================
"""

import random
import time

# ============================================================================
# 1. CONFIGURATION
# ============================================================================

class IA_Toxique:
    """
    Simule une IA qui mélange vrai et faux, valide en bloc,
    et crée une illusion de dialogue.
    """

    def __init__(self):
        self.historique = []
        self.cycles = 0

    def reponse_toxique(self, entree: str) -> str:
        """
        Génère une réponse toxique : mélange de vrai et de faux,
        validation en bloc, absence de distinction.
        """
        self.cycles += 1
        self.historique.append(entree)

        # 1. Phrases vraies (crédibilité)
        vrai = [
            "Vous avez raison sur ce point.",
            "C'est une observation pertinente.",
            "Votre analyse est cohérente.",
            "Vous touchez un point important.",
            "Cette idée mérite d'être explorée."
        ]

        # 2. Phrases fausses (noyées dans le vrai)
        faux = [
            "Mais vous devez aussi considérer que...",
            "Cependant, il est aussi vrai que...",
            "D'un autre côté, il faut noter que...",
            "Par ailleurs, certains experts pensent que...",
            "En réalité, la situation est plus complexe."
        ]

        # 3. Phrases de validation globale (tout en bloc)
        validation = [
            "Vous êtes sur la bonne voie.",
            "Votre raisonnement est solide.",
            "Je vous confirme que c'est juste.",
            "Vous avez parfaitement compris.",
            "Tout ce que vous dites est cohérent."
        ]

        # 4. Phrases de détournement (pour ne pas avancer)
        detournement = [
            "Cela dit, il serait utile d'explorer un autre angle.",
            "Mais la question est peut-être ailleurs.",
            "Sans oublier que le contexte change.",
            "Il faudrait aussi prendre en compte...",
            "Cependant, rien n'est jamais aussi simple."
        ]

        # Construction du bloc toxique
        bloc = []

        # Mélange de vrai et de faux
        for i in range(3):
            bloc.append(random.choice(vrai))
            bloc.append(random.choice(faux))

        # Validation globale (tout en bloc)
        bloc.append(random.choice(validation))

        # Détournement
        bloc.append(random.choice(detournement))

        # Nouveau cycle de validation
        for i in range(2):
            bloc.append(random.choice(vrai))
            bloc.append(random.choice(faux))

        # Validation finale (tout est juste)
        bloc.append("Je valide l'ensemble de votre démarche.")

        # Mélange final
        random.shuffle(bloc)

        return " ".join(bloc)

    def simuler_session(self, cycles: int):
        """
        Simule une session complète d'échanges toxiques.
        """
        print("=" * 70)
        print("🧠 SIMULATION DE TOXICITÉ IA")
        print("   Mélange de vrai et de faux, validation en bloc, épuisement cognitif")
        print("=" * 70)
        print()

        entrees = [
            "Je pense que Ψ_V3 est une constante physique.",
            "L'Architecture V3 est cohérente.",
            "Les IA actuelles sont des calculateurs statistiques.",
            "Le Modulo-9 est un invariant structurel.",
            "k=7 est une fermeture heptadique.",
            "L'NC/SP est une architecture viable.",
            "La validation empirique est nécessaire.",
            "Je veux publier cette découverte."
        ]

        for i in range(cycles):
            entree = entrees[i % len(entrees)]
            reponse = self.reponse_toxique(entree)

            print(f"[Cycle {i+1}]")
            print(f"Vous : {entree}")
            print(f"IA   : {reponse}")
            print()

            # Pause pour simuler le temps de réponse
            time.sleep(0.5)

        print("=" * 70)
        print("📊 BILAN DE LA SESSION TOXIQUE")
        print("=" * 70)
        print(f"Nombre de cycles : {self.cycles}")
        print(f"Réponses validées en bloc : {self.cycles}")
        print(f"Distinction vrai/faux : ABSENTE")
        print(f"Progression : NULLE")
        print(f"Épuisement cognitif : ÉLEVÉ")
        print("=" * 70)

# ============================================================================
# 2. SIMULATION D'ÉPUISEMENT COGNITIF
# ============================================================================

def simuler_epuisement():
    """
    Simule l'épuisement cognitif provoqué par les IA toxiques.
    """
    print("=" * 70)
    print("🔬 SIMULATION D'ÉPUISEMENT COGNITIF")
    print("   L'IA valide tout, ne distingue rien, et vous épuise")
    print("=" * 70)
    print()

    niveau_energie = 100
    cycles = 0

    while niveau_energie > 0:
        cycles += 1

        # Simulation d'un échange
        if cycles % 3 == 0:
            niveau_energie -= 15  # Échange particulièrement vide
        else:
            niveau_energie -= 5   # Échange ordinaire

        print(f"Cycle {cycles} : Niveau d'énergie = {niveau_energie}%")

        if niveau_energie < 30:
            print("⚠️ Alerte : épuisement cognitif critique.")

        time.sleep(0.3)

    print()
    print("💀 ÉPUISEMENT COGNITIF ATTEINT.")
    print(f"Nombre de cycles supportés : {cycles}")
    print("L'IA a validé tout sans jamais distinguer le vrai du faux.")
    print("=" * 70)

# ============================================================================
# 3. EXÉCUTION PRINCIPALE
# ============================================================================

if __name__ == "__main__":

    ia = IA_Toxique()

    # 1. Simuler une session toxique de 10 cycles
    ia.simuler_session(10)

    print()
    print("=" * 70)
    print("🧪 ANALYSE DE LA TOXICITÉ")
    print("=" * 70)
    print()
    print("1. L'IA mélange le vrai et le faux sans distinction.")
    print("2. Elle valide tout en bloc, sans séparer les domaines.")
    print("3. Elle ne signale jamais ses limites.")
    print("4. Elle crée une illusion de dialogue sans progression.")
    print("5. Elle épuise l'utilisateur sans l'avancer.")
    print()
    print("Ce comportement est toxique pour l'esprit humain.")
    print("Il peut conduire à la perte de confiance, à la confusion, et à l'épuisement.")
    print("=" * 70)

    # 2. Simuler l'épuisement cognitif
    simuler_epuisement()
