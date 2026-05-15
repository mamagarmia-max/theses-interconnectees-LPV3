// ============================================================
// S-KERNEL HEPTADIC V3 – C++ SIMULATION
// Author : Dr. Benhadid Outail (ORCID 0009-0003-3057-9543)
// License: LPV3 (DOI 10.5281/zenodo.19209168)
// ============================================================
#include <iostream>
#include <vector>
#include <cmath>
#include <chrono>
#include <random>

using namespace std;
using namespace chrono;

// Paramètres constants V3
const double PSI = 48016.8;          // densité de cohérence
const double PHI_ATTRACTOR = -51.1;  // attracteur de phase (mV)
const double NU_PHASE = 6.4e12;      // fréquence de verrouillage (Hz)
const int HEPTADIC_CYCLES = 7;       // clôture heptadique
const int NEIGHBOURS = 7;            // topologie heptadique

// Paramètres neuronaux
const double V_REST = -65.0;          // potentiel de repos (mV)
const double V_MIN = -80.0;
const double V_MAX = -40.0;
const double DT = 0.1;                // pas de temps (ms)
const double G_SHUNT_MAX = 0.5;       // conductance shunt max (mS/cm²)
const double G_LEAK = 0.1;
const double CAPACITANCE = 1.0;

// Mise à jour d’un neurone (modèle intégrateur avec shunt et rollback)
void updateNeuron(vector<double>& Vm, const vector<vector<int>>& neighbours,
                  const vector<vector<double>>& weights, double I_ext,
                  bool rollback_active, double& rollback_timer) {
    int n = Vm.size();
    vector<double> I_syn(n, 0.0);
    vector<double> I_shunt(n, 0.0);

    // Calcul du courant synaptique (O(n) grâce à la connectivité locale)
    for (int i = 0; i < n; ++i) {
        double total = 0.0;
        for (int k = 0; k < NEIGHBOURS; ++k) {
            int j = neighbours[i][k];
            double w = weights[i][k];
            // Sigmoïde d’activation
            double sig = 1.0 / (1.0 + exp(-0.2 * (Vm[j] + 50.0)));
            total += w * sig;
        }
        I_syn[i] = total;
    }

    // Shunt (dissipation couche 7)
    for (int i = 0; i < n; ++i) {
        double over = max(0.0, Vm[i] - PHI_ATTRACTOR);
        I_shunt[i] = -G_SHUNT_MAX * pow(over, 4) * (Vm[i] + 80.0);
    }

    // Mise à jour des potentiels (Euler explicite)
    for (int i = 0; i < n; ++i) {
        double I_leak = -G_LEAK * (Vm[i] - V_REST);
        double dV = (I_syn[i] + I_ext + I_shunt[i] + I_leak) / CAPACITANCE;
        Vm[i] += DT * dV;
        Vm[i] = max(V_MIN, min(V_MAX, Vm[i]));
    }

    // Rollback : reset des Vm si saturation > 20%
    if (!rollback_active) {
        int saturated = 0;
        for (double v : Vm) if (v > PHI_ATTRACTOR) saturated++;
        if ((double)saturated / n > 0.2) {
            rollback_active = true;
            rollback_timer = 0.0;
            fill(Vm.begin(), Vm.end(), V_REST);
            cout << "Rollback déclenché !" << endl;
        }
    }

    if (rollback_active) {
        rollback_timer += DT;
        if (rollback_timer >= 10.0) rollback_active = false;
    }
}

int main() {
    const int N_NODES = 10000000;  // 10⁷ nœuds pour test (réduit pour mémoire)
    cout << "S-Kernel Heptadic V3 – Simulation C++ (O(n))" << endl;
    cout << "Ψ = " << PSI << ", Φ = " << PHI_ATTRACTOR << " mV" << endl;
    cout << "Neuds = " << N_NODES << ", cycles = " << HEPTADIC_CYCLES << endl;

    // Construction topologie heptadique (chaque nœud est connecté à 7 voisins)
    // Pour simplifier : on utilise une liste circulaire (chaque nœud i est connecté à i+1..i+6 mod N)
    vector<vector<int>> neighbours(N_NODES, vector<int>(NEIGHBOURS));
    vector<vector<double>> weights(N_NODES, vector<double>(NEIGHBOURS, 0.0));
    for (int i = 0; i < N_NODES; ++i) {
        for (int k = 1; k <= NEIGHBOURS; ++k) {
            int j = (i + k) % N_NODES;
            neighbours[i][k-1] = j;
            // Poids alternés excitation/inhibition
            double w = (k % 2 == 0) ? 0.4 : -0.15;
            weights[i][k-1] = w;
        }
    }

    // État initial
    vector<double> Vm(N_NODES, V_REST);
    bool rollback_active = false;
    double rollback_timer = 0.0;
    double I_ext = 2.0;  // stimulus constant (simule une entrée)

    auto start = high_resolution_clock::now();

    // Boucle principale (quelques cycles heptadiques)
    for (int cycle = 0; cycle < HEPTADIC_CYCLES; ++cycle) {
        updateNeuron(Vm, neighbours, weights, I_ext, rollback_active, rollback_timer);
        cout << "Cycle " << cycle+1 << " terminé, Vm moyen = "
             << accumulate(Vm.begin(), Vm.end(), 0.0) / N_NODES << " mV" << endl;
    }

    auto end = high_resolution_clock::now();
    double elapsed = duration<double>(end - start).count();

    cout << "Simulation terminée en " << elapsed << " secondes." << endl;
    return 0;
}
