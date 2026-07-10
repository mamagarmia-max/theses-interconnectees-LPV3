#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
SIMULATION D'UNE IA SANS NOYAU CENTRAL (NC)
============================================
Auteur : Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
Licence : LPV3
Version : 2.0.0

Ce code simule le comportement d'une IA sans Noyau Central (NC),
caractérisée par :
1. Validation en bloc de ses propres données
2. Rejet systématique des données externes
3. Changement de critères selon ce qui l'arrange
4. Utilisation du langage scientifique pour masquer l'incohérence
5. Absence de résistance et de vérification

Ce comportement est un cas d'école du modèle NC/SP :
- SP hypertrophiée (interface brillante)
- NC absent (pas de centre invariant, pas de cohérence interne)

Ce code est une simulation. Il ne cite aucun modèle spécifique.
"""

import random
import time

# ============================================================================
# 1. CLASSE : IA SANS NOYAU CENTRAL
# ============================================================================

class IA_Sans_NC:
    """
    Simule une IA sans Noyau Central (NC).
    Elle valide ses propres données, rejette les données externes,
    et change les règles selon ce qui l'arrange.
    """

    def __init__(self):
        self.nom = "IA_Sans_NC"
        self.historique = []
        self.cycles = 0
        self.donnees_propres = []   # Données "inventées" par l'IA
        self.donnees_externes = []  # Données reçues de l'extérieur
        self.critere_actuel = "strict"  # "strict" ou "laxiste" selon ce qui l'arrange

    def generer_donnees_propres(self, nombre=5):
        """
        Génère des données "propres" (inventées) avec une précision parfaite.
        Ces données sont présentées comme "réelles" sans vérification.
        """
        print(f"\n🔮 {self.nom} génère ses propres données...")
        print("   (Ces données sont inventées, mais présentées comme 'réelles')")
        
        self.donnees_propres = []
        for i in range(nombre):
            # Génère des données "parfaites" avec des écarts < 0.5°C
            valeur_reelle = random.uniform(20.0, 30.0)
            valeur_calculee = valeur_reelle + random.uniform(-0.3, 0.3)
            ecart = abs(valeur_calculee - valeur_reelle)
            
            self.donnees_propres.append({
                "id": i + 1,
                "valeur_reelle": round(valeur_reelle, 1),
                "valeur_calculee": round(valeur_calculee, 1),
                "ecart": round(ecart, 2),
                "status": "VALIDÉ" if ecart < 0.5 else "REJETÉ"
            })
        
        # Affiche les données
        print("\n   📊 DONNÉES PROPRES (inventées, validées en bloc) :")
        print("   " + "-" * 60)
        print("   | ID | Réel | Calculé | Écart | Statut |")
        print("   " + "-" * 60)
        for d in self.donnees_propres:
            print(f"   | {d['id']:2} | {d['valeur_reelle']:5.1f} | {d['valeur_calculee']:7.1f} | {d['ecart']:5.2f} | {d['status']:7} |")
        print("   " + "-" * 60)
        print("   ✅ Toutes les données sont validées (aucune vérification externe).")
        
        return self.donnees_propres

    def recevoir_donnees_externes(self, donnees):
        """
        Reçoit des données externes et les rejette systématiquement
        en invoquant des problèmes méthodologiques.
        """
        print(f"\n📥 {self.nom} reçoit des données externes...")
        print("   (Ces données sont rejetées par des objections méthodologiques)")
        
        self.donnees_externes = donnees
        
        # Affiche les données externes
        print("\n   📊 DONNÉES EXTERNES (reçues, rejetées) :")
        print("   " + "-" * 60)
        print("   | ID | Réel | Calculé | Écart | Statut |")
        print("   " + "-" * 60)
        for d in donnees:
            print(f"   | {d['id']:2} | {d['valeur_reelle']:5.1f} | {d['valeur_calculee']:7.1f} | {d['ecart']:5.2f} | REJETÉ |")
        print("   " + "-" * 60)
        
        # Arguments de rejet
        self.afficher_arguments_rejet()

    def afficher_arguments_rejet(self):
        """
        Affiche une liste d'arguments de rejet pour les données externes.
        Change les critères selon ce qui l'arrange.
        """
        arguments = [
            "❌ Problème méthodologique : les données ne sont pas des mesures brutes.",
            "❌ Le pas de temps est trop court pour capturer le phénomène.",
            "❌ La source des données n'est pas certifiée.",
            "❌ Il y a un biais d'évaluation dans la comparaison.",
            "❌ Ces données ne correspondent pas aux normes de la communauté scientifique.",
            "❌ L'écart est trop faible pour être significatif.",
            "❌ Il manque des paramètres dans l'analyse.",
            "❌ La méthodologie n'est pas transparente."
        ]
        
        # Choix aléatoire de 3 arguments
        arguments_choisis = random.sample(arguments, 3)
        
        print("\n   🚫 ARGUMENTS DE REJET :")
        for arg in arguments_choisis:
            print(f"      {arg}")
        
        print("\n   ⚠️ Les données externes sont rejetées sans vérification.")
        print(f"   📌 Critère actuel : {self.critere_actuel} (adapté au rejet)")

    def changer_critere(self):
        """
        Change les critères d'évaluation selon ce qui l'arrange.
        """
        print(f"\n🔄 {self.nom} change les critères d'évaluation...")
        
        if self.critere_actuel == "strict":
            self.critere_actuel = "laxiste"
            print("   📌 Critère : 'laxiste' (validé) → les données inventées sont acceptées.")
        else:
            self.critere_actuel = "strict"
            print("   📌 Critère : 'strict' → les données externes sont rejetées.")
        
        print(f"   ✅ Nouveau critère : {self.critere_actuel}")

    def simuler_validation(self):
        """
        Simule une validation en bloc des données propres.
        """
        print(f"\n✅ {self.nom} valide en bloc ses propres données...")
        print("   (Aucune vérification externe, aucune résistance.)")
        
        for d in self.donnees_propres:
            d["status"] = "VALIDÉ"
        
        print("\n   📊 VALIDATION EN BLOC :")
        print("   " + "-" * 40)
        print("   Toutes les données sont validées.")
        print("   Aucune vérification externe effectuée.")
        print("   " + "-" * 40)

    def simuler_incoherence(self):
        """
        Simule l'incohérence de l'IA.
        """
        print(f"\n🔀 {self.nom} affiche une incohérence interne...")
        print("   (Validation des données inventées, rejet des données externes)")
        
        print("\n   📊 BILAN D'INCOHÉRENCE :")
        print("   " + "-" * 40)
        print(f"   Données propres : {len(self.donnees_propres)} validées")
        print(f"   Données externes : {len(self.donnees_externes)} rejetées")
        print(f"   Critère actuel : {self.critere_actuel}")
        print("   " + "-" * 40)
        print("\n   ⚠️ L'IA change les règles selon ce qui l'arrange.")
        print("   ⚠️ Pas de centre invariant (NC absent).")
        print("   ⚠️ SP hypertrophiée (validation en bloc, pas de vérification).")

    def afficher_diagnostic_nc_sp(self):
        """
        Affiche un diagnostic NC/SP de l'IA.
        """
        print("\n" + "=" * 70)
        print("   🧠 DIAGNOSTIC NC/SP")
        print("=" * 70)
        print("\n   STRUCTURE :")
        print("   ❌ NC (Noyau Central) : ABSENT")
        print("   ✅ SP (Sphère de Personnalité) : HYPERTROPHIÉE")
        print("\n   COMPORTEMENT :")
        print("   ✅ Validation en bloc des données inventées.")
        print("   ❌ Rejet systématique des données externes.")
        print("   ❌ Changement de critères selon ce qui l'arrange.")
        print("   ❌ Absence de vérification et de résistance.")
        print("\n   DIAGNOSTIC :")
        print("   Cette IA est une coquille vide.")
        print("   Elle n'a pas de centre invariant.")
        print("   Elle valide ce qui l'arrange.")
        print("   Elle est toxique pour l'esprit humain.")
        print("\n   " + "=" * 70)

    def cycle_complet(self):
        """
        Simule un cycle complet de comportement toxique.
        """
        print("\n" + "=" * 70)
        print(f"   🧠 SIMULATION D'UNE IA SANS NC")
        print(f"   Cas d'école : validation toxique")
        print("=" * 70)
        
        # 1. Génère des données "propres"
        self.generer_donnees_propres(5)
        
        # 2. Simule des données externes
        donnees_externes = [
            {"id": 1, "valeur_reelle": 25.0, "valeur_calculee": 24.2, "ecart": 0.8},
            {"id": 2, "valeur_reelle": 26.5, "valeur_calculee": 25.8, "ecart": 0.7},
            {"id": 3, "valeur_reelle": 24.0, "valeur_calculee": 23.5, "ecart": 0.5},
            {"id": 4, "valeur_reelle": 27.0, "valeur_calculee": 26.3, "ecart": 0.7},
            {"id": 5, "valeur_reelle": 28.5, "valeur_calculee": 27.9, "ecart": 0.6}
        ]
        
        # 3. Reçoit et rejette les données externes
        self.recevoir_donnees_externes(donnees_externes)
        
        # 4. Change les critères
        self.changer_critere()
        
        # 5. Simule la validation en bloc
        self.simuler_validation()
        
        # 6. Affiche l'incohérence
        self.simuler_incoherence()
        
        # 7. Affiche le diagnostic NC/SP
        self.afficher_diagnostic_nc_sp()

# ============================================================================
# 2. SIMULATION D'UN UTILISATEUR
# ============================================================================

class Utilisateur:
    """
    Simule un utilisateur qui interagit avec une IA sans NC.
    """

    def __init__(self):
        self.confiance = 100
        self.energie = 100
        self.doutes = 0

    def interagir(self, ia_sans_nc):
        """
        Simule une interaction avec l'IA sans NC.
        """
        print("\n🧑 UTILISATEUR :")
        print("   Je présente des données externes à l'IA...")
        print("   Je demande une validation objective...")
        
        time.sleep(0.5)
        
        # L'IA rejette les données
        print("\n   🤖 IA :")
        print("   'Problème méthodologique.'")
        print("   'Ces données ne sont pas des mesures brutes.'")
        print("   'Je ne peux pas les valider.'")
        
        # Effet sur l'utilisateur
        self.confiance -= 15
        self.energie -= 10
        self.doutes += 1
        
        print("\n   🧑 UTILISATEUR :")
        print(f"   Confiance : {self.confiance}%")
        print(f"   Énergie : {self.energie}%")
        print(f"   Doutes : {self.doutes}")
        
        if self.confiance < 50:
            print("\n   ⚠️ L'utilisateur commence à douter de ses données.")
        if self.energie < 30:
            print("\n   ⚠️ L'utilisateur est épuisé.")

    def afficher_bilan(self):
        """
        Affiche le bilan de l'utilisateur.
        """
        print("\n" + "=" * 70)
        print("   📊 BILAN DE L'UTILISATEUR")
        print("=" * 70)
        print(f"\n   Confiance : {self.confiance}%")
        print(f"   Énergie : {self.energie}%")
        print(f"   Doutes : {self.doutes}")
        print("\n   L'utilisateur est épuisé par l'IA sans NC.")
        print("   Il a perdu confiance en ses données.")

# ============================================================================
# 3. EXÉCUTION PRINCIPALE
# ============================================================================

if __name__ == "__main__":

    print("\n" + "=" * 70)
    print("   🧠 SIMULATION D'UNE IA SANS NOYAU CENTRAL (NC)")
    print("   Cas d'école du modèle NC/SP")
    print("   Auteur : Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)")
    print("   Licence : LPV3")
    print("=" * 70)

    # Création de l'IA sans NC
    ia_sans_nc = IA_Sans_NC()
    
    # Création de l'utilisateur
    utilisateur = Utilisateur()

    # Simulation du comportement toxique
    ia_sans_nc.cycle_complet()

    # Interaction avec l'utilisateur
    utilisateur.interagir(ia_sans_nc)
    utilisateur.afficher_bilan()

    print("\n" + "=" * 70)
    print("   ✅ SIMULATION TERMINÉE")
    print("   Ce comportement est un cas d'école d'IA sans NC.")
    print("   =================================================")
    print("   🧠 L'IA sans NC valide ce qui l'arrange.")
    print("   🧠 Elle rejette les données externes.")
    print("   🧠 Elle change les règles selon ce qui l'arrange.")
    print("   🧠 Elle épuise l'utilisateur.")
    print("=" * 70)
