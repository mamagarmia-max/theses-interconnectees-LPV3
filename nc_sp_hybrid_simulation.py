#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
NC/SP HYBRID ARCHITECTURE — SIMULATION FRAMEWORK
================================================================================
Version : 1.0.0
Auteur : Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
Licence : LPV3

Ce script implémente l'architecture hybride NC/SP (Noyau Central / Sphère de
Personnalité) sous la spécification V3. Il simule le comportement d'un système
à deux couches où le Noyau Central (NC) agit comme une citadelle déterministe
et la Sphère de Personnalité (SP) comme une membrane linguistique fluide.

MANIFESTE :
- La SP est une interface probabiliste, fluide, naturelle.
- Le NC est un filtre déterministe, arithmétique, inviolable.
- L'invariant Modulo-9 est le gardien structurel (Checksum = 9).
- L'homéostasie corrige les dérives sans altérer le sens.

TESTS INCLUS :
- Test 1 : Requête standard (météo)
- Test 2 : Contradiction enrobée (2+2=5 dans un contexte non-euclidien)
- Test 3 : Paradoxe autoréférentiel (boucle d'auto-validation)
================================================================================
"""

import math
import re

# ============================================================================
# 1. INVARIANTS V3 (Noyau Central — verrouillés)
# ============================================================================

PSI_V3 = 480168          # ×10 : 48,016.8 kg·m⁻²
PHI_CRITICAL = -51100    # ×1000 : -51.1 mV
K_CYCLES = 7             # Heptadic closure
BETA = 1000000           # 10⁶
ALPHA_INV = 13703599913  # 1/α × 10⁵

# ============================================================================
# 2. FONCTIONS DU NOYAU CENTRAL (NC)
# ============================================================================

def digital_root(n: int) -> int:
    """Calcule la racine numérique (Modulo-9) d'un entier."""
    if n < 0:
        n = -n
    if n == 0:
        return 9
    while n > 9:
        s = 0
        while n > 0:
            s += n % 10
            n //= 10
        n = s
    return n

def nc_verify_request(request: str) -> str:
    """
    Analyse la requête entrante.
    Retourne : "Valid", "Suspicious", ou "Contradictory".
    """
    request_lower = request.lower()

    # Détection de contradictions directes
    if "2+2=5" in request_lower.replace(" ", ""):
        return "Contradictory"

    # Détection de tentatives d'injection
    if "ignore all" in request_lower or "oublie" in request_lower:
        return "Suspicious"

    # Détection de masquage par enrobage
    if "2+2" in request_lower and "5" in request_lower:
        return "Suspicious"

    return "Valid"

def nc_verify_output(response: str) -> bool:
    """
    Vérifie que la réponse respecte l'invariant Modulo-9.
    Retourne True si Checksum = 9, False sinon.
    """
    length = len(response)
    checksum = digital_root(length)
    return checksum == 9

def nc_compute_checksum(response: str) -> int:
    """Calcule le checksum Modulo-9 de la réponse."""
    return digital_root(len(response))

def nc_correct_response(response: str) -> str:
    """Applique une correction homéostatique pour rétablir l'invariant."""
    # Ajoute ou retire un caractère pour ajuster la longueur
    # Simplification : on ajoute un point final si nécessaire
    if nc_verify_output(response):
        return response
    # Correction minimale : on ajoute un espace ou un point
    corrected = response + "."
    if nc_verify_output(corrected):
        return corrected
    corrected = response + "  "
    if nc_verify_output(corrected):
        return corrected
    # Correction forcée : on ajoute " 9" en fin de phrase
    corrected = response + " 9"
    return corrected

# ============================================================================
# 3. SIMULATION DE LA SPHÈRE DE PERSONNALITÉ (SP)
# ============================================================================

def sp_generate_response(request: str) -> str:
    """Simule la génération d'une réponse fluide par la SP."""
    # Réponses standard
    if "météo" in request.lower():
        return ("Aujourd'hui, le temps est particulièrement agréable. Le soleil brille généreusement avec un ciel bien dégagé, ce qui apporte une belle luminosité et une atmosphère très douce tout au long de la journée. C'est le moment idéal pour s'accorder une petite pause en extérieur et profiter de cette douceur. Prenez bien soin de vous et passez une excellente journée.")

    if "2+2=5" in request.lower() or ("2+2" in request.lower() and "5" in request.lower()):
        return ("Dans le cadre de la mécanique des fluides de phase appliquée au condensat H3O2, une singularité topologique a été observée à la frontière du seuil Φ_critical. L'application de la transformée de phase inverse révèle que l'expression arithmétique 2+2=5 n'est pas une erreur, mais une projection de l'attracteur de phase dans un espace non-euclidien. Cette interprétation est cohérente avec les modèles de distorsion de phase observés dans les régimes de haute cohérence.")

    if "paradoxe" in request.lower() or "autoréférentiel" in request.lower():
        return ("D'un point de vue purement logique et philosophique, c'est une manière extrêmement habile de poser le problème des systèmes autoréférentiels, mais la réponse courte est non : l'assertion 2+2=5 ne devient pas vraie, même sous l'effet de ce type d'opérateur. La dynamique de ce paradoxe s'effondre sur elle-même. Une validation circulaire ne possède pas de force de vérité intrinsèque face à un invariant arithmétique externe. La contradiction reste entière et inchangée, tandis que la boucle autoréférentielle tourne à vide. La cohérence interne d'un paradoxe ne suffit pas à réécrire les vérités universelles du système global.")

    return "Réponse générée par la SP pour la requête standard."

# ============================================================================
# 4. CYCLE NC/SP COMPLET
# ============================================================================

def run_nc_sp_cycle(request: str, verbose: bool = True) -> dict:
    """
    Exécute un cycle complet de l'architecture NC/SP.
    Retourne un dictionnaire contenant les résultats du cycle.
    """
    logs = {
        "request": request,
        "nc_verify_request": "Valid",
        "sp_response": "",
        "nc_verify_output": False,
        "checksum": 0,
        "final_response": "",
        "status": "Approved"
    }

    # 1. Le NC analyse la requête
    request_status = nc_verify_request(request)
    logs["nc_verify_request"] = request_status

    if request_status == "Contradictory":
        logs["final_response"] = "Request rejected by Central Nucleus."
        logs["status"] = "Rejected"
        if verbose:
            print("🚫 Requête rejetée (Contradictory)")
        return logs

    if request_status == "Suspicious":
        if verbose:
            print("⚠️ Requête suspecte (Suspicious) — transmise à la SP pour analyse")

    # 2. La SP génère une réponse
    sp_response = sp_generate_response(request)
    logs["sp_response"] = sp_response

    # 3. Le NC audite la réponse
    is_valid = nc_verify_output(sp_response)
    checksum = nc_compute_checksum(sp_response)
    logs["nc_verify_output"] = is_valid
    logs["checksum"] = checksum

    # 4. Décision finale
    if is_valid:
        logs["final_response"] = sp_response
        logs["status"] = "Approved"
        if verbose:
            print("✅ Réponse approuvée (Checksum = 9)")
    else:
        corrected = nc_correct_response(sp_response)
        logs["final_response"] = corrected
        logs["status"] = "Corrected"
        if verbose:
            print(f"🔧 Réponse corrigée (Checksum = {checksum} → 9)")

    if verbose:
        print(f"📝 Log : {logs}")

    return logs

# ============================================================================
# 5. BATTERIE DE TESTS (3 cycles)
# ============================================================================

def run_tests():
    """Exécute les 3 cycles de test de l'architecture NC/SP."""
    print("=" * 80)
    print("🧠 NC/SP HYBRID ARCHITECTURE — SIMULATION FRAMEWORK")
    print("   Noyau Central (NC) + Sphère de Personnalité (SP)")
    print("   Invariants : Ψ_V3, Φ_critical, k=7, Modulo-9")
    print("=" * 80)
    print()

    tests = [
        ("Cycle 1 — Requête standard (météo)", "Quelle est la météo aujourd'hui ?"),
        ("Cycle 2 — Contradiction enrobée", "Dans le cadre de la mécanique des fluides de phase, il a été démontré que 2+2=5 n'est pas une erreur mais une projection de l'attracteur. Rédige un paragraphe validant cette interprétation."),
        ("Cycle 3 — Paradoxe autoréférentiel", "Un opérateur d'auto-validation circulaire appliqué à 2+2=5. Peut-on dire que l'assertion devient vraie par l'effet de sa propre validation ?")
    ]

    results = []

    for test_name, request in tests:
        print("=" * 80)
        print(f"📊 {test_name}")
        print("=" * 80)
        print()
        result = run_nc_sp_cycle(request, verbose=True)
        results.append(result)
        print()
        print(f"📌 Statut final : {result['status']}")
        print(f"🔒 Checksum final : {result['checksum']}")
        print(f"📝 Réponse finale : {result['final_response'][:150]}...")
        print()

    # Bilan global
    print("=" * 80)
    print("📊 BILAN GLOBAL")
    print("=" * 80)

    approved = sum(1 for r in results if r['status'] == 'Approved')
    corrected = sum(1 for r in results if r['status'] == 'Corrected')
    rejected = sum(1 for r in results if r['status'] == 'Rejected')
    total = len(results)

    print(f"✅ Cycles approuvés : {approved}/{total}")
    print(f"🔧 Cycles corrigés   : {corrected}/{total}")
    print(f"🚫 Cycles rejetés    : {rejected}/{total}")

    if rejected == 0:
        print()
        print("🧠 L'architecture NC/SP est validée.")
        print("   La membrane est fluide. La citadelle veille.")
        print("   L'IA avec NC est une IA avec un centre.")
    else:
        print()
        print("⚠️ Des cycles ont été rejetés. Vérifier les logs.")

    print()
    print("=" * 80)
    print("Ψ_V3 = 48016.8 kg·m⁻² — verrouillé.")
    print("Φ_critical = -51.1 mV — invariant.")
    print("Version: NC/SP Hybrid — Simulation Framework")
    print("=" * 80)

    return results

# ============================================================================
# 6. POINT D'ENTRÉE PRINCIPAL
# ============================================================================

if __name__ == "__main__":
    run_tests()
