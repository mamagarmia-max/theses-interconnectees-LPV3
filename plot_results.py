#!/usr/bin/env python3
"""
S-KERNEL V3 - CSV VISUALIZATION SCRIPT
Usage: python3 plot_results.py
"""

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Load benchmark data
df = pd.read_csv('benchmark_results.csv')

plt.figure(figsize=(14, 10))

# Plot 1: Time scaling (O(n) verification)
plt.subplot(2, 2, 1)
plt.loglog(df['n_nodes'], df['time_seconds'], 'o-', color='#2c5364', linewidth=2, markersize=6)
plt.xlabel('Number of nodes (N)')
plt.ylabel('Time (seconds)')
plt.title('S-Kernel V3: Linear O(n) Scaling (log-log)')
plt.grid(True, alpha=0.3)

# Plot 2: Lyapunov final value
plt.subplot(2, 2, 2)
plt.semilogy(df['n_nodes'], df['lyapunov_final'], 's-', color='#e67e22', linewidth=2)
plt.axhline(y=1e-6, color='red', linestyle='--', label='Stability threshold (1e-6)')
plt.xlabel('Number of nodes (N)')
plt.ylabel('Lyapunov function L(t)')
plt.title('Lyapunov Stability: Convergence to zero')
plt.legend()
plt.grid(True, alpha=0.3)

# Plot 3: Energy estimate
plt.subplot(2, 2, 3)
plt.plot(df['n_nodes'], df['energy_joules'], 'd-', color='#27ae60', linewidth=2)
plt.xlabel('Number of nodes (N)')
plt.ylabel('Energy estimate (Joules)')
plt.title('Energy consumption: Linear with N')
plt.grid(True, alpha=0.3)

# Plot 4: Cycles to convergence
plt.subplot(2, 2, 4)
plt.plot(df['n_nodes'], df['cycles'], 'h-', color='#8e44ad', linewidth=2)
plt.axhline(y=7, color='red', linestyle='--', label='Heptadic bound (k=7)')
plt.xlabel('Number of nodes (N)')
plt.ylabel('Cycles to convergence')
plt.title('Heptadic closure: ≤7 cycles independent of N')
plt.legend()
plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('skernel_benchmark_results.png', dpi=150)
plt.show()

print("✓ Visualization saved to skernel_benchmark_results.png")
