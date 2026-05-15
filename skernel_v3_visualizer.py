# ============================================================
# S-KERNEL HEPTADIC V3 – PYTHON SIMULATION
# Author : Dr. Benhadid Outail (ORCID 0009-0003-3057-9543)
# License: LPV3 (DOI 10.5281/zenodo.19209168)
# ============================================================
import numpy as np
import matplotlib.pyplot as plt
import time

# Paramètres V3
PSI = 48016.8
PHI_ATTRACTOR = -51.1
NU_PHASE = 6.4e12
HEPTADIC_CYCLES = 7
NEIGHBOURS = 7

# Paramètres neuronaux
V_REST = -65.0
V_MIN, V_MAX = -80.0, -40.0
DT = 0.1          # ms
G_SHUNT_MAX = 0.5
G_LEAK = 0.1
CAPACITANCE = 1.0

def update_neurons(Vm, neighbours, weights, I_ext, rollback_active, rollback_timer):
    n = len(Vm)
    I_syn = np.zeros(n)
    I_shunt = np.zeros(n)

    # Courant synaptique (O(n))
    for i in range(n):
        total = 0.0
        for k in range(NEIGHBOURS):
            j = neighbours[i][k]
            w = weights[i][k]
            sig = 1.0 / (1.0 + np.exp(-0.2 * (Vm[j] + 50.0)))
            total += w * sig
        I_syn[i] = total

    # Shunt
    over = np.maximum(0, Vm - PHI_ATTRACTOR)
    I_shunt = -G_SHUNT_MAX * (over**4) * (Vm + 80.0)

    # Intégration
    I_leak = -G_LEAK * (Vm - V_REST)
    dV = (I_syn + I_ext + I_shunt + I_leak) / CAPACITANCE
    Vm += DT * dV
    Vm = np.clip(Vm, V_MIN, V_MAX)

    # Rollback
    if not rollback_active:
        sat_ratio = np.mean(Vm > PHI_ATTRACTOR)
        if sat_ratio > 0.2:
            rollback_active = True
            rollback_timer = 0.0
            Vm[:] = V_REST
            print("Rollback déclenché !")
    if rollback_active:
        rollback_timer += DT
        if rollback_timer >= 10.0:
            rollback_active = False

    return Vm, rollback_active, rollback_timer

def main():
    N_NODES = 10000   # Pour démonstration (augmentez à 1e6 si RAM suffit)
    print(f"S-Kernel Heptadic V3 – Simulation Python (O(n))")
    print(f"Ψ = {PSI}, Φ = {PHI_ATTRACTOR} mV")
    print(f"Nœuds = {N_NODES}, cycles = {HEPTADIC_CYCLES}")

    # Topologie heptadique (circulaire)
    neighbours = []
    weights = []
    for i in range(N_NODES):
        neigh = []
        wlist = []
        for k in range(1, NEIGHBOURS+1):
            j = (i + k) % N_NODES
            neigh.append(j)
            w = 0.4 if (k % 2 == 0) else -0.15
            wlist.append(w)
        neighbours.append(neigh)
        weights.append(wlist)

    Vm = np.full(N_NODES, V_REST, dtype=float)
    I_ext = 2.0
    rollback_active = False
    rollback_timer = 0.0
    history = []

    start = time.time()

    for cycle in range(HEPTADIC_CYCLES):
        Vm, rollback_active, rollback_timer = update_neurons(
            Vm, neighbours, weights, I_ext, rollback_active, rollback_timer)
        mean_v = np.mean(Vm)
        history.append(mean_v)
        print(f"Cycle {cycle+1} : Vm moyen = {mean_v:.2f} mV")

    elapsed = time.time() - start
    print(f"Simulation terminée en {elapsed:.2f} secondes.")

    # Affichage
    plt.figure(figsize=(10,4))
    plt.plot(range(1, HEPTADIC_CYCLES+1), history, 'o-', color='#0055ff')
    plt.axhline(y=PHI_ATTRACTOR, color='r', linestyle='--', label=f'Attracteur Φ = {PHI_ATTRACTOR} mV')
    plt.xlabel('Cycle heptadique')
    plt.ylabel('Potentiel membranaire moyen (mV)')
    plt.title('Convergence du S-Kernel Heptadic V3')
    plt.legend()
    plt.grid(True)
    plt.show()

if __name__ == "__main__":
    main()
