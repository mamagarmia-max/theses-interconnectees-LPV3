#!/usr/bin/env python3
# SPDX-License-Identifier: (GPL-2.0 OR LPV3)
"""
simulate_crash.py - Simulation de crash d'avion pour meta_validator_v3

Génère des données de crash corrompues et vérifie que meta_validator_v3
résiste sans planter.

Auteur: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
Standard: Blida V3
"""

import json
import subprocess
import os
import sys
import random

def generate_crash_data(corrupt_level=0.7):
    """
    Génère un fichier JSON simulant les données d'un crash aérien.
    Si corrupt_level > 0, le fichier est volontairement corrompu.
    """
    data = {
        "event": "crash_on_runway",
        "timestamp": "2025-06-01T15:30:00Z",
        "aircraft": "Boeing 737",
        "runway": "18R",
        "sensors": {
            "vibration": random.choice(["ERR", "OVERLOAD", 9999, "NULL"]),
            "temperature": random.randint(-50, 2000),
            "pressure": random.choice(["NULL", 0, "LOST"])
        },
        "logs": ["Mayday! Mayday!", "Engine failure", "Losing altitude", "Impact imminent"],
        "num_tests": random.choice([0, -1, 48, 100]),  # 0 déclenche division par zéro protégée
        "pass": random.randint(0, 100),
        "tests_published": random.choice([True, False]),
        "emergency_beacon": "ACTIVE"
    }
    filename = "crash_data.json"
    with open(filename, "w") as f:
        json.dump(data, f, indent=2)
    
    if random.random() < corrupt_level:
        # Corrompt le fichier (troncature ou ajout de caractères invalides)
        with open(filename, "ab") as f:
            f.write(b"}{")  # JSON invalide
        print("   [SIM] Données corrompues injectées.")
    return filename

def compile_meta_validator():
    """Compile meta_validator_v3.c s'il n'existe pas."""
    if not os.path.exists("meta_validator_v3"):
        print("   [SIM] Compilation de meta_validator_v3...")
        result = subprocess.run(["gcc", "-Wall", "-Wextra", "-O2", "-o", "meta_validator_v3",
                                 "meta_validator_v3.c", "-lm"], capture_output=True)
        if result.returncode != 0:
            print("   ❌ Échec de compilation de meta_validator_v3")
            print(result.stderr.decode())
            return False
        print("   ✅ Compilation réussie.")
    return True

def run_simulation():
    print("\n" + "=" * 60)
    print("🧪 SIMULATION DE CRASH AÉRIEN")
    print("   Test de robustesse du META-VALIDATOR V3")
    print("=" * 60)
    
    # Vérifier que le code existe
    if not os.path.exists("meta_validator_v3.c"):
        print("❌ meta_validator_v3.c introuvable. Placez ce script dans le même dossier que le code.")
        return False
    
    if not compile_meta_validator():
        return False
    
    success = 0
    total_tests = 5
    
    for i in range(total_tests):
        print(f"\n--- SIMULATION {i+1}/{total_tests} ---")
        json_file = generate_crash_data(corrupt_level=0.7)
        print(f"   Fichier généré : {json_file}")
        
        try:
            result = subprocess.run(["./meta_validator_v3", json_file],
                                    capture_output=True, text=True, timeout=5)
            print(f"   Code retour : {result.returncode}")
            if result.returncode in (0, 1):
                print("   ✅ Le meta-validator a résisté (pas de crash).")
                success += 1
            else:
                print(f"   ⚠️ Code retour inattendu : {result.returncode}")
            if result.stdout:
                print("   STDOUT (extrait) :", result.stdout[:200].replace("\n", " "))
            if result.stderr:
                print("   STDERR :", result.stderr[:200])
        except subprocess.TimeoutExpired:
            print("   ❌ TIMEOUT (5s) – possible boucle infinie ?")
        except Exception as e:
            print(f"   ❌ Exception : {e}")
        finally:
            if os.path.exists(json_file):
                os.remove(json_file)
    
    print("\n" + "=" * 60)
    print(f"📊 RÉSULTAT : {success}/{total_tests} simulations réussies (sans crash)")
    if success == total_tests:
        print("✅ LE META-VALIDATOR V3 PASSE L'ÉPREUVE.")
        print("   Résiste aux données corrompues, divisions par zéro, fichiers invalides.")
    else:
        print("⚠️ Certaines simulations ont échoué. Revoir le code.")
    print("=" * 60)
    return success == total_tests

def self_simulation():
    """Version rapide pour test unitaire"""
    print("\n🔧 AUTO-SIMULATION (self-test)")
    # Crée un fichier JSON valide minimal
    with open("_test_crash.json", "w") as f:
        json.dump({"test": "ok", "num_tests": 10, "pass": 9}, f)
    # Lance meta_validator_v3
    result = subprocess.run(["./meta_validator_v3", "_test_crash.json"],
                            capture_output=True)
    os.remove("_test_crash.json")
    if result.returncode == 0:
        print("   ✅ Auto-simulation OK")
        return True
    else:
        print("   ❌ Auto-simulation échouée")
        return False

if __name__ == "__main__":
    # Si lancé avec --self-test, fait juste une petite validation
    if len(sys.argv) > 1 and sys.argv[1] == "--self-test":
        success = self_simulation()
        sys.exit(0 if success else 1)
    else:
        success = run_simulation()
        sys.exit(0 if success else 1)
