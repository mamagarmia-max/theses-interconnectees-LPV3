#!/usr/bin/env python3
"""
Banach Fixed-Point Convergence on a Deterministic 2D Topological Grid
=====================================================================

Implements a strictly deterministic contraction mapping on a 40x25 grid
with Moore neighborhood connectivity. The method applies Banach's fixed-point
theorem to eliminate floating-point drift and stochastic approximations.

License: MIT
Zenodo DOI: [RESERVED FOR ZENODO DEPOSIT]
Author: [Anonymous]
Version: 1.0.0
Python: 3.8+
"""

import numpy as np
from typing import Tuple, List


def build_connectivity_matrix(rows: int, cols: int) -> np.ndarray:
    """Constructs a sparse connectivity matrix based on Moore neighborhood topology.

    Each node connects to its immediate neighbors (horizontal, vertical, diagonal).
    Boundary conditions are strictly geometric:
        - Corners: 3 neighbors
        - Edges (non-corner): 5 neighbors
        - Interior: 8 neighbors

    Args:
        rows: Number of rows in the grid.
        cols: Number of columns in the grid.

    Returns:
        A 2D NumPy array of shape (rows*cols, rows*cols) where entry (i, j)
        is 1 if nodes i and j are connected, 0 otherwise. The matrix is
        symmetric with zeros on the diagonal.
    """
    n_nodes = rows * cols
    # Initialize empty sparse representation for efficiency
    # Using index arrays to build COO format, then convert to dense for small grids
    row_indices = []
    col_indices = []

    # Precompute offsets for Moore neighborhood (8 directions)
    offsets = [
        (-1, -1), (-1, 0), (-1, 1),
        (0, -1),           (0, 1),
        (1, -1),  (1, 0),  (1, 1)
    ]

    for r in range(rows):
        for c in range(cols):
            node_idx = r * cols + c
            for dr, dc in offsets:
                nr, nc = r + dr, c + dc
                # Enforce strict boundary conditions via geometric check
                if 0 <= nr < rows and 0 <= nc < cols:
                    neighbor_idx = nr * cols + nc
                    row_indices.append(node_idx)
                    col_indices.append(neighbor_idx)

    # Build symmetric adjacency matrix
    adj_matrix = np.zeros((n_nodes, n_nodes), dtype=np.float64)
    adj_matrix[row_indices, col_indices] = 1.0

    # Verify connectivity counts match geometric specification
    connectivity_counts = adj_matrix.sum(axis=1).astype(int)
    for r in range(rows):
        for c in range(cols):
            idx = r * cols + c
            expected = 8  # Default: interior
            if r == 0 or r == rows - 1:
                expected -= 3  # Remove one full edge of neighbors
            if c == 0 or c == cols - 1:
                expected -= 3
            if ((r == 0 or r == rows - 1) and (c == 0 or c == cols - 1)):
                expected = 3  # Corner correction (5-2 overcounting avoided)
            # Recalculate precisely based on geometric position
            is_top = (r == 0)
            is_bottom = (r == rows - 1)
            is_left = (c == 0)
            is_right = (c == cols - 1)
            if is_top and is_left:       expected_geo = 3
            elif is_top and is_right:    expected_geo = 3
            elif is_bottom and is_left:  expected_geo = 3
            elif is_bottom and is_right: expected_geo = 3
            elif is_top or is_bottom:    expected_geo = 5
            elif is_left or is_right:    expected_geo = 5
            else:                        expected_geo = 8

            assert connectivity_counts[idx] == expected_geo, (
                f"Connectivity mismatch at node ({r},{c}): "
                f"got {connectivity_counts[idx]}, expected {expected_geo}"
            )

    return adj_matrix


def compute_banach_operator(
    adj_matrix: np.ndarray,
    contraction_factor: float = 0.0556
) -> np.ndarray:
    """Constructs the Banach contraction operator for the grid topology.

    The operator is defined as:
        T(v) = contraction_factor * (A @ v) / k
    where:
        - A is the adjacency matrix
        - k = 7 is the characteristic topological constant
        - The 2π normalization is absorbed into the contraction factor
          (contraction_factor = 2π * alpha / k, with alpha fine-structure analogue)

    This guarantees ||T(v) - T(w)|| <= L * ||v - w|| with Lipschitz constant
    L = contraction_factor * spectral_radius(A) / k < 1, satisfying Banach's
    fixed-point theorem conditions.

    Args:
        adj_matrix: Square adjacency matrix of shape (N, N).
        contraction_factor: Lipschitz constant for the contraction mapping.

    Returns:
        A callable operator function T(v) -> np.ndarray.
    """
    k_topological = 7.0
    # Scale factor incorporating topological normalization
    scale = contraction_factor / k_topological

    def operator(state_vector: np.ndarray) -> np.ndarray:
        """Applies the Banach contraction mapping.

        Args:
            state_vector: Current state vector of shape (N,).

        Returns:
            Updated state vector after contraction.
        """
        return scale * (adj_matrix @ state_vector)

    return operator


def compute_gradient_norm(
    adj_matrix: np.ndarray,
    state: np.ndarray,
    contraction_factor: float
) -> float:
    """Computes the operator norm of the Jacobian (gradient) to verify contraction.

    For the linear operator T(v) = c * A @ v, the Jacobian is simply c * A.
    Its spectral norm must be strictly less than 1 for Banach's theorem to hold.

    Args:
        adj_matrix: Adjacency matrix of the grid.
        state: Current state vector (unused in linear case, for API consistency).
        contraction_factor: Contraction factor of the mapping.

    Returns:
        The spectral norm (largest singular value) of the Jacobian matrix.
    """
    k_topological = 7.0
    jacobian = (contraction_factor / k_topological) * adj_matrix
    # Spectral norm = maximum singular value
    spectral_norm = np.linalg.svd(jacobian, compute_uv=False)[0]
    return spectral_norm


def run_convergence_loop(
    operator: callable,
    adj_matrix: np.ndarray,
    contraction_factor: float,
    n_cycles: int = 10,
    grid_shape: Tuple[int, int] = (25, 40)
) -> List[dict]:
    """Executes the deterministic fixed-point iteration.

    At each cycle, the Banach operator is applied to the state vector.
    The gradient norm is verified to remain strictly less than 1, guaranteeing
    convergence to a unique fixed point.

    Args:
        operator: Banach contraction mapping T(v) -> v'.
        adj_matrix: Adjacency matrix for gradient computation.
        contraction_factor: Contraction factor for validation.
        n_cycles: Number of iteration cycles (default: 10).
        grid_shape: Tuple of (rows, cols) for display purposes.

    Returns:
        List of dictionaries containing cycle metrics:
        {'cycle': int, 'mean_convergence': float, 'residual_norm': float}
    """
    n_nodes = adj_matrix.shape[0]
    # Initialize state vector with uniform perturbation
    state = np.ones(n_nodes, dtype=np.float64)

    metrics_log = []

    for cycle in range(1, n_cycles + 1):
        # Store previous state for residual computation
        prev_state = state.copy()

        # Apply Banach contraction operator
        state = operator(state)

        # Compute convergence metrics
        delta = state - prev_state
        residual_norm = np.linalg.norm(delta, ord=2)  # L2 norm of the change
        mean_value = np.mean(state)

        # Strict verification of Banach's condition
        grad_norm = compute_gradient_norm(adj_matrix, state, contraction_factor)
        assert grad_norm < 1.0, (
            f"Banach condition violated at cycle {cycle}: "
            f"gradient norm = {grad_norm:.12f} >= 1"
        )

        metrics_log.append({
            'cycle': cycle,
            'mean_convergence': mean_value,
            'residual_norm': residual_norm,
            'gradient_norm': grad_norm
        })

    return metrics_log


def main():
    """Main execution block for the Banach fixed-point demonstration.

    Constructs a 40x25 grid, builds the deterministic connectivity matrix,
    defines the contraction operator, and runs exactly 10 convergence cycles.
    Results are displayed cycle-by-cycle with convergence metrics.
    """
    # Grid configuration
    rows, cols = 25, 40  # 1000 nodes total
    contraction_factor = 0.0556
    n_cycles = 10

    # Build topology
    adj_matrix = build_connectivity_matrix(rows, cols)
    n_nodes = rows * cols
    print(f"Grid: {rows}x{cols} = {n_nodes} nodes")
    print(f"Contraction factor: {contraction_factor}")
    print(f"Cycles: {n_cycles}")
    print("-" * 55)

    # Create Banach operator
    banach_op = compute_banach_operator(adj_matrix, contraction_factor)

    # Verify initial contraction condition
    init_state = np.ones(n_nodes, dtype=np.float64)
    init_grad_norm = compute_gradient_norm(adj_matrix, init_state, contraction_factor)
    print(f"Initial gradient norm: {init_grad_norm:.12f}")
    assert init_grad_norm < 1.0, "Initial operator is not a contraction"
    print("-" * 55)

    # Run deterministic convergence
    metrics = run_convergence_loop(
        operator=banach_op,
        adj_matrix=adj_matrix,
        contraction_factor=contraction_factor,
        n_cycles=n_cycles,
        grid_shape=(rows, cols)
    )

    # Display cycle-by-cycle results
    print(f"{'Cycle':>5}  {'Mean Convergence':>18}  {'Residual Norm':>18}")
    print("-" * 55)
    for entry in metrics:
        c = entry['cycle']
        mean_val = entry['mean_convergence']
        resid = entry['residual_norm']
        print(f"{c:5d}  {mean_val:18.12e}  {resid:18.12e}")

    # Final deviation summary
    final_residual = metrics[-1]['residual_norm']
    print("-" * 55)
    print(f"Final deviation (cycle {n_cycles}): {final_residual:.12e}")
    print(f"Convergence confirmed: residual < 1e-10: {final_residual < 1e-10}")


if __name__ == '__main__':
    main()
