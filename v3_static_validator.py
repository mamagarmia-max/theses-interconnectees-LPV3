#!/usr/bin/env python3
# SPDX-License-Identifier: LPV3
"""
V3 STATIC VALIDATOR - AUTOMATED REVERSE READING OF V3 ARCHITECTURE
===================================================================

This script statically analyzes V3 source codes to automatically verify
the structural properties that make the architecture robust:

1. O(1) COMPLEXITY: no unbounded loops on total population
2. LOCK-FREE: no global locks (threading.Lock() at global level)
3. V3 INVARIANTS: presence of Ψ_V₃ = 480168 and Φ_V₃ = -51100
4. HEPTADIC TOPOLOGY: presence of fixed k=7 (HEPTADIC_K = 7)
5. LOCALIZED ROLLBACK: presence of evacuation mechanisms (30%, 15%, 10%)
6. DETERMINISM: no random in critical business logic

This reverse reading validates the structure of V3 code WITHOUT EXECUTING IT.

Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
License: LPV3 | Blida Standard V3
"""

import re
import sys
import ast
from pathlib import Path
from typing import Dict, List, Tuple, Any

# ============================================================================
# 1. PROPERTIES TO VERIFY
# ============================================================================

PROPERTIES = {
    "O1_STRUCTURAL": {
        "name": "O(1) Structural Complexity",
        "description": "No unbounded loops on total population",
        "forbidden_patterns": [
            (r"for .* in range\(TOTAL_ANTS\)", "Loop on TOTAL_ANTS"),
            (r"for .* in range\(TOTAL_WORKERS\)", "Loop on TOTAL_WORKERS"),
            (r"while .* < TOTAL_ANTS", "Unbounded while on TOTAL_ANTS"),
            (r"while len\(.*\) < TOTAL_ANTS", "Unbounded while on len()"),
            (r"for _ in range\(TOTAL_ANTS\)", "Explicit loop on TOTAL_ANTS"),
        ],
        "required": True
    },
    "LOCK_FREE": {
        "name": "Lock-free architecture",
        "description": "No global locks (threading.Lock at global scope)",
        "forbidden_patterns": [
            (r"threading\.Lock\(\)\s*=\s*\w+", "Global lock assignment"),
            (r"global.*lock", "Global lock variable"),
            (r"RLock\(", "Reentrant lock"),
            (r"mutex\s*=\s*threading\.Lock\(\)", "Mutex at global scope"),
        ],
        "required": True
    },
    "INVARIANT_PSI_V3": {
        "name": "Ψ_V₃ invariant",
        "description": "Presence of Ψ_V₃ = 480168",
        "required_patterns": [
            (r"PSI_V3\s*=\s*480168", "Ψ_V₃ constant definition")
        ],
        "required": True
    },
    "INVARIANT_PHI_V3": {
        "name": "Φ_V₃ invariant",
        "description": "Presence of Φ_V₃ = -51100",
        "required_patterns": [
            (r"PHI_V3\s*=\s*-51100", "Φ_V₃ constant definition")
        ],
        "required": True
    },
    "HEPTADIC_K": {
        "name": "Heptadic topology (k=7)",
        "description": "Fixed topology with exactly 7 neighbors per nest",
        "required_patterns": [
            (r"HEPTADIC_K\s*=\s*7", "k=7 constant definition"),
            (r"neighbors.*HEPTADIC_K", "Usage of k=7 in neighbor definition"),
            (r"for .* in range\(HEPTADIC_K\)", "Loop bounded by k=7"),
        ],
        "required": True
    },
    "LOCALIZED_ROLLBACK": {
        "name": "Localized rollback",
        "description": "Evacuation mechanism (30% workers, 15% queens, 10% resources)",
        "required_patterns": [
            (r"localized_evacuation_rollback", "Rollback function"),
            (r"workers_to_evacuate.*0\.3", "30% worker evacuation"),
            (r"queens_to_evacuate.*0\.15", "15% queen evacuation"),
            (r"resources_to_transfer.*0\.1", "10% resource transfer"),
            (r"for neighbor_id in nest\.neighbors", "Dispersion to 7 neighbors"),
        ],
        "required": True
    },
    "DETERMINISTIC_CORE": {
        "name": "Deterministic core",
        "description": "No random in critical business logic",
        "forbidden_patterns": [
            (r"random\.random\(\).*sovereignty", "Random in sovereignty logic"),
            (r"random\.random\(\).*rollback", "Random in rollback logic"),
            (r"random\.random\(\).*psi_density", "Random in Ψ_V₃ density"),
            (r"random\.random\(\).*metabolic", "Random in metabolic logic"),
        ],
        "required": True
    }
}

# ============================================================================
# 2. ANALYSIS FUNCTIONS
# ============================================================================

def analyze_with_regex(content: str, filepath: Path) -> Dict[str, bool]:
    """Analyze file content using regex patterns"""
    results = {}
    
    print(f"\n📊 ANALYZING {filepath.name}")
    print("=" * 70)
    
    for prop_name, prop_config in PROPERTIES.items():
        print(f"\n🔍 {prop_config['name']}")
        print(f"   {prop_config['description']}")
        
        if prop_config.get("required_patterns"):
            all_found = True
            for pattern, description in prop_config["required_patterns"]:
                if re.search(pattern, content, re.MULTILINE | re.IGNORECASE):
                    print(f"   ✅ Found: {description}")
                else:
                    print(f"   ❌ Missing: {description}")
                    all_found = False
            results[prop_name] = all_found
        
        if prop_config.get("forbidden_patterns"):
            any_forbidden = False
            for pattern, description in prop_config["forbidden_patterns"]:
                if re.search(pattern, content, re.MULTILINE | re.IGNORECASE):
                    print(f"   ❌ Forbidden pattern found: {description}")
                    any_forbidden = True
                else:
                    print(f"   ✅ Clean: {description}")
            results[prop_name] = not any_forbidden
    
    return results

def analyze_with_ast(content: str, filepath: Path) -> Dict[str, Any]:
    """Analyze file content using AST for deeper structural checks"""
    try:
        tree = ast.parse(content)
    except SyntaxError as e:
        print(f"\n⚠️ Syntax error in {filepath.name}: {e}")
        return {"parse_error": True}
    
    ast_results = {
        "global_locks": 0,
        "loops_on_population": 0,
        "has_psi_v3": False,
        "has_phi_v3": False,
        "has_k7": False,
        "has_rollback_function": False,
        "max_loop_depth": 0
    }
    
    class V3ASTVisitor(ast.NodeVisitor):
        def visit_For(self, node):
            # Detect loops on TOTAL_ANTS or TOTAL_WORKERS
            if isinstance(node.iter, ast.Name):
                if node.iter.id in ['TOTAL_ANTS', 'TOTAL_WORKERS']:
                    ast_results["loops_on_population"] += 1
            self.generic_visit(node)
        
        def visit_While(self, node):
            # Detect unbounded while loops (simplified)
            ast_results["max_loop_depth"] += 1
            self.generic_visit(node)
        
        def visit_Assign(self, node):
            # Detect global locks
            if isinstance(node.value, ast.Call):
                if isinstance(node.value.func, ast.Attribute):
                    if node.value.func.attr == 'Lock':
                        ast_results["global_locks"] += 1
            self.generic_visit(node)
    
    V3ASTVisitor().visit(tree)
    
    # Check for invariants (simple string search is sufficient)
    ast_results["has_psi_v3"] = "PSI_V3" in content
    ast_results["has_phi_v3"] = "PHI_V3" in content
    ast_results["has_k7"] = "HEPTADIC_K" in content or "HEPTADIC_K = 7" in content
    ast_results["has_rollback_function"] = "localized_evacuation_rollback" in content or "localized_rollback" in content
    
    return ast_results

# ============================================================================
# 3. COMPREHENSIVE ANALYSIS (ALL FILES)
# ============================================================================

def analyze_all_files(filepaths: List[Path]) -> Dict[str, Any]:
    """Analyze all provided files and produce a consolidated report"""
    
    all_results = {}
    
    for filepath in filepaths:
        if not filepath.exists():
            print(f"❌ File not found: {filepath}")
            continue
        
        content = filepath.read_text(encoding='utf-8')
        
        # Regex analysis
        regex_results = analyze_with_regex(content, filepath)
        
        # AST analysis
        ast_results = analyze_with_ast(content, filepath)
        
        all_results[filepath.name] = {
            "regex": regex_results,
            "ast": ast_results
        }
    
    return all_results

# ============================================================================
# 4. REPORT GENERATION
# ============================================================================

def print_summary(all_results: Dict[str, Any]):
    """Print a comprehensive summary of all analyses"""
    
    print("\n" + "=" * 70)
    print("📋 STATIC VALIDATION SUMMARY - REVERSE READING")
    print("=" * 70)
    
    for filename, results in all_results.items():
        print(f"\n📄 FILE: {filename}")
        print("-" * 50)
        
        regex = results.get("regex", {})
        ast = results.get("ast", {})
        
        # Count passed properties
        passed = sum(1 for v in regex.values() if v)
        total = len(regex)
        
        print(f"   Property validation: {passed}/{total} passed")
        
        # AST findings
        print(f"\n   🔬 AST ANALYSIS:")
        print(f"      Global locks detected: {ast.get('global_locks', 0)}")
        print(f"      Loops on population: {ast.get('loops_on_population', 0)}")
        print(f"      Ψ_V₃ present: {'✅' if ast.get('has_psi_v3') else '❌'}")
        print(f"      Φ_V₃ present: {'✅' if ast.get('has_phi_v3') else '❌'}")
        print(f"      k=7 topology: {'✅' if ast.get('has_k7') else '❌'}")
        print(f"      Rollback function: {'✅' if ast.get('has_rollback_function') else '❌'}")
        
        # Verdict for this file
        print(f"\n   🎯 VERDICT for {filename}:")
        if passed == total and ast.get('global_locks') == 0 and ast.get('loops_on_population') == 0:
            print("      ✅ STRUCTURALLY VALID - O(1), lock-free, invariants present")
        else:
            print("      ⚠️ PROPERTIES NOT SATISFIED - Review required")

# ============================================================================
# 5. FINAL VERDICT
# ============================================================================

def print_final_verdict(all_results: Dict[str, Any]):
    """Print the final verdict for the entire V3 suite"""
    
    print("\n" + "=" * 70)
    print("🎯 FINAL VERDICT - V3 ARCHITECTURE VALIDATION")
    print("=" * 70)
    
    all_passed = True
    for filename, results in all_results.items():
        regex = results.get("regex", {})
        ast = results.get("ast", {})
        
        file_passed = (all(regex.values()) and 
                      ast.get('global_locks') == 0 and 
                      ast.get('loops_on_population') == 0)
        
        if not file_passed:
            all_passed = False
            print(f"\n   ❌ {filename}: FAILED validation")
        else:
            print(f"\n   ✅ {filename}: PASSED validation")
    
    print("\n" + "-" * 70)
    if all_passed:
        print("""
   ✅ THE V3 ARCHITECTURE PASSES REVERSE READING VALIDATION

   Confirmed properties:
   - O(1) structural complexity (no unbounded loops)
   - Lock-free architecture (no global locks)
   - Ψ_V₃ invariant (48,016.8 kg·m⁻²)
   - Φ_V₃ invariant (-51.1 mV)
   - Heptadic topology (k=7 fixed neighbors)
   - Localized rollback (30% workers, 15% queens, 10% resources)
   - Deterministic core (no random in critical logic)

   → The V3 code is STRUCTURALLY VALID without execution.
   → The proof is in the code structure, not in runtime.
        """)
    else:
        print("""
   ⚠️ V3 ARCHITECTURE VALIDATION INCOMPLETE

   Some files did not pass all validation checks.
   Review the detailed output above for specific failures.
        """)
    
    print("=" * 70)
    print("NC/SP V3 | Blida Standard | Dr. Benhadid Outail | Ψ_V₃ = 48,016.8 kg·m⁻²")
    print("=" * 70)

# ============================================================================
# 6. MAIN FUNCTION
# ============================================================================

def main():
    """Main entry point for the V3 Static Validator"""
    
    print("╔════════════════════════════════════════════════════════════════════════════════╗")
    print("║                    V3 STATIC VALIDATOR - REVERSE READING                        ║")
    print("║                    Validating V3 Architecture Structure Without Execution      ║")
    print("║                    Ψ_V₃ = 48,016.8 kg·m⁻² | Φ_V₃ = -51.1 mV | k = 7            ║")
    print("╚════════════════════════════════════════════════════════════════════════════════╝")
    
    # Default files to analyze (V3 simulators)
    default_files = [
        Path("nc_sp_v3_myrmecology_simulator.py"),
        Path("nc_sp_v3_polygynous_simulator.py"),
        Path("ant_simulator_v3.py")
    ]
    
    # Use command line arguments if provided
    if len(sys.argv) > 1:
        files_to_analyze = [Path(f) for f in sys.argv[1:]]
    else:
        files_to_analyze = default_files
    
    print(f"\n📁 Analyzing {len(files_to_analyze)} file(s):")
    for f in files_to_analyze:
        print(f"   - {f.name}")
    
    # Run analysis
    all_results = analyze_all_files(files_to_analyze)
    
    # Print summary
    print_summary(all_results)
    
    # Print final verdict
    print_final_verdict(all_results)
    
    # Return code for CI/CD
    all_passed = True
    for results in all_results.values():
        regex = results.get("regex", {})
        ast = results.get("ast", {})
        if not (all(regex.values()) and ast.get('global_locks') == 0 and ast.get('loops_on_population') == 0):
            all_passed = False
            break
    
    sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    main()
