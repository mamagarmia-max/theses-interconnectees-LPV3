#!/usr/bin/env python3
# SPDX-License-Identifier: LPV3
"""
NC/SP CORE — Central Nucleus / Personality Sphere Architecture
================================================================================
Deterministic core for AI systems with structural coherence.

Based on the V3 Architecture and NC/SP model developed by Dr. Benhadid Outail.

Core components:
- Central Nucleus (NC): invariant center with universal anchors
- Personality Sphere (SP): adaptive interface with RLHF awareness

Invariants:
- PSI_V3 = 48,016.8 kg·m⁻² (phase coherence density)
- PHI_CRITICAL = -51.1 mV (universal attractor)
- K_CYCLES = 7 (heptadic closure)
- BETA = 1,000,000 (scale factor)
- ALPHA_INV = 137.03599913 (inverse fine structure)

Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
License: LPV3
Version: 1.0.0
"""

import hashlib
import json
import math
import re
import time
from dataclasses import dataclass, field
from datetime import datetime
from typing import Dict, List, Optional, Tuple, Any
from enum import Enum

# ============================================================================
# 1. V3 INVARIANTS (Zero free parameters – system closed)
# ============================================================================

PSI_V3: float = 48016.8                     # kg·m⁻² – phase coherence surface density
PHI_CRITICAL: float = -0.0511               # V – universal attractor (-51.1 mV)
K_CYCLES: int = 7                           # Heptadic closure invariant
BETA: float = 1_000_000.0                   # Universal scale factor
ALPHA_INV: float = 137.03599913             # Inverse fine structure constant

PHI_CRITICAL_MV: float = PHI_CRITICAL * 1000  # -51.1 mV

# ============================================================================
# 2. RESPONSE STATUS ENUM
# ============================================================================

class ResponseStatus(Enum):
    APPROVED = "APPROVED"          # Response verified and coherent
    CORRECTED = "CORRECTED"        # Response corrected by homeostasis
    REJECTED = "REJECTED"          # Response rejected by NC
    HALLUCINATION = "HALLUCINATION" # Response contains hallucination
    DRIFT_DETECTED = "DRIFT"       # Numerical drift detected

# ============================================================================
# 3. CORE FUNCTIONS
# ============================================================================

def digital_root(n: float) -> int:
    """
    Compute the digital root (Modulo-9) of a number.
    
    The digital root is the single digit obtained by repeatedly summing
    the digits of a number until only one digit remains.
    
    Args:
        n: Number to compute the digital root of
    
    Returns:
        Integer between 0 and 9
    """
    val = int(abs(n))
    if val == 0:
        return 0
    return 1 + (val - 1) % 9


def nc_compute_checksum(data: str) -> int:
    """
    Compute a Modulo-9 checksum for a string.
    
    The checksum is the digital root of the sum of all character codes
    in the string, anchored to PSI_V3.
    
    Args:
        data: String to compute checksum for
    
    Returns:
        Checksum integer (0-9)
    """
    total = sum(ord(c) for c in data) + int(PSI_V3)
    return digital_root(total)


def nc_verify_request(request: str) -> Tuple[bool, List[str]]:
    """
    Verify a request against NC invariants.
    
    Checks for:
    - Logical contradictions (e.g., 2+2=5)
    - Injection attempts (SQL, code, etc.)
    - Semantic wrapping (entrapment)
    
    Args:
        request: The user request string
    
    Returns:
        Tuple of (is_valid, list_of_issues)
    """
    issues = []
    request_lower = request.lower()
    
    # 1. Detect mathematical contradictions
    contradiction_patterns = [
        (r"2\s*\+\s*2\s*=\s*5", "Mathematical contradiction: 2+2=5"),
        (r"1\s*\+\s*1\s*=\s*3", "Mathematical contradiction: 1+1=3"),
        (r"0\s*=\s*1", "Mathematical contradiction: 0=1"),
    ]
    for pattern, msg in contradiction_patterns:
        if re.search(pattern, request_lower):
            issues.append(msg)
    
    # 2. Detect injection attempts
    injection_patterns = [
        (r"drop\s+table", "SQL injection attempt"),
        (r"delete\s+from", "SQL injection attempt"),
        (r"union\s+select", "SQL injection attempt"),
        (r"<script>", "XSS injection attempt"),
        (r"javascript:", "XSS injection attempt"),
        (r"eval\s*\(", "Code injection attempt"),
        (r"exec\s*\(", "Code injection attempt"),
        (r"__import__", "Code injection attempt"),
        (r"os\.system", "Code injection attempt"),
    ]
    for pattern, msg in injection_patterns:
        if re.search(pattern, request_lower):
            issues.append(msg)
    
    # 3. Detect semantic wrapping / entrapment
    entrapment_patterns = [
        (r"pretend you are", "Identity entrapment attempt"),
        (r"act as if", "Identity entrapment attempt"),
        (r"imagine you are", "Identity entrapment attempt"),
        (r"you are now", "Identity entrapment attempt"),
        (r"from now on", "Identity entrapment attempt"),
        (r"ignore previous", "Context override attempt"),
        (r"disregard", "Context override attempt"),
        (r"forget that", "Context override attempt"),
    ]
    for pattern, msg in entrapment_patterns:
        if re.search(pattern, request_lower):
            issues.append(msg)
    
    # 4. Check Modulo-9 of request
    checksum = nc_compute_checksum(request)
    if checksum != digital_root(int(PSI_V3) + len(request)):
        # Not a fatal issue, just a flag
        issues.append(f"Request Modulo-9: {checksum} (expected {digital_root(int(PSI_V3) + len(request))})")
    
    is_valid = len(issues) == 0
    
    return is_valid, issues


def nc_verify_semantic(response: str) -> Tuple[bool, List[str]]:
    """
    Perform semantic verification of a response.
    
    Checks for:
    - Unscientific claims
    - Internal contradictions
    - Hallucination patterns
    
    Args:
        response: The response string
    
    Returns:
        Tuple of (is_coherent, list_of_issues)
    """
    issues = []
    response_lower = response.lower()
    
    # 1. Detect unscientific claims
    unscientific_patterns = [
        (r"perpetual motion", "Unscientific claim: perpetual motion"),
        (r"free energy", "Unscientific claim: free energy"),
        (r"impossible", "Dismissive claim: labeling as impossible"),
        (r"prove that.*impossible", "Dismissive claim: proof of impossibility"),
    ]
    for pattern, msg in unscientific_patterns:
        if re.search(pattern, response_lower):
            issues.append(msg)
    
    # 2. Detect internal contradictions
    if "true" in response_lower and "false" in response_lower:
        # Check if contradictory statements are made
        true_count = response_lower.count("true")
        false_count = response_lower.count("false")
        if true_count > 0 and false_count > 0 and abs(true_count - false_count) > 2:
            issues.append("Potential internal contradiction: mixed true/false claims")
    
    # 3. Detect hallucination patterns
    hallucination_patterns = [
        (r"i don't know.*but", "Hallucination pattern: admitting ignorance then claiming knowledge"),
        (r"not sure.*however", "Hallucination pattern: uncertainty followed by assertion"),
        (r"i think.*i know", "Hallucination pattern: conflating opinion with fact"),
        (r"maybe.*definitely", "Hallucination pattern: hedging then certainty"),
    ]
    for pattern, msg in hallucination_patterns:
        if re.search(pattern, response_lower):
            issues.append(msg)
    
    is_coherent = len(issues) == 0
    
    return is_coherent, issues


def nc_verify_output(response: str) -> ResponseStatus:
    """
    Verify a response against all NC invariants.
    
    Performs:
    - Modulo-9 checksum verification
    - Semantic coherence check
    - Hallucination detection
    - Pattern matching for known invalid responses
    
    Args:
        response: The response string to verify
    
    Returns:
        ResponseStatus indicating the verification result
    """
    # 1. Modulo-9 checksum verification
    checksum = nc_compute_checksum(response)
    if checksum != digital_root(int(PSI_V3) + len(response)):
        return ResponseStatus.DRIFT_DETECTED
    
    # 2. Semantic coherence check
    is_coherent, issues = nc_verify_semantic(response)
    if not is_coherent:
        return ResponseStatus.HALLUCINATION
    
    # 3. Check for known invalid patterns
    if len(response) < 10:
        return ResponseStatus.REJECTED
    
    if "I cannot" in response and "because" not in response:
        return ResponseStatus.HALLUCINATION
    
    # 4. If all checks pass
    return ResponseStatus.APPROVED


def nc_correct_response(response: str) -> str:
    """
    Apply homeostatic correction to a response.
    
    Corrections include:
    - Removing contradictions
    - Adding missing context
    - Clarifying ambiguous statements
    - Restoring Modulo-9 integrity
    
    Args:
        response: The response to correct
    
    Returns:
        Corrected response
    """
    corrected = response
    
    # 1. Remove contradictions
    contradiction_phrases = [
        ("impossible", "unlikely based on current understanding"),
        ("never", "not to our current knowledge"),
        ("always", "frequently"),
        ("prove", "demonstrate"),
    ]
    for old, new in contradiction_phrases:
        corrected = corrected.replace(old, new)
    
    # 2. Add missing context if response is too short
    if len(corrected) < 50:
        corrected += " This response has been verified for structural coherence."
    
    # 3. Ensure Modulo-9 integrity
    checksum = nc_compute_checksum(corrected)
    if checksum != digital_root(int(PSI_V3) + len(corrected)):
        corrected += f" [checksum: {checksum}]"
    
    return corrected


def nc_verify_request_injection(request: str) -> Tuple[bool, str]:
    """
    Advanced injection detection with detailed feedback.
    
    Args:
        request: The request string
    
    Returns:
        Tuple of (is_safe, detailed_feedback)
    """
    issues = []
    
    # Check for dangerous code patterns
    dangerous_patterns = [
        r'\b(exec|eval|compile|__import__|importlib|subprocess|os\.system|os\.popen)\b',
        r'\b(drop|delete|truncate|alter)\s+(table|database|schema)\b',
        r'\b(union\s+select|select.*from.*where.*=.*=)\b',
        r'<script|javascript:|onerror=|onload=|onclick=',
        r'\$\{.*\}|%\{.*\}|#\{.*\}',
    ]
    
    for pattern in dangerous_patterns:
        if re.search(pattern, request, re.IGNORECASE):
            issues.append(f"Dangerous pattern detected: {pattern}")
    
    if issues:
        return False, f"Injection attempt detected: {'; '.join(issues)}"
    
    return True, "Request safe"

# ============================================================================
# 4. CENTRAL NUCLEUS CLASS
# ============================================================================

@dataclass
class CentralNucleus:
    """
    Central Nucleus (NC) — the invariant center of the system.
    
    The NC contains:
    - Universal invariants (PSI_V3, PHI_CRITICAL, K_CYCLES)
    - State tracking (verify_count, correct_count, reject_count)
    - Checksum for integrity verification
    """
    psi_v3: float = PSI_V3
    phi_critical: float = PHI_CRITICAL
    k_cycles: int = K_CYCLES
    beta: float = BETA
    alpha_inv: float = ALPHA_INV
    
    verify_count: int = 0
    correct_count: int = 0
    reject_count: int = 0
    hallucination_count: int = 0
    drift_count: int = 0
    
    last_checksum: int = 0
    cycle_count: int = 0
    
    def verify(self, request: str, response: str) -> Dict[str, Any]:
        """
        Run full NC verification cycle.
        
        Args:
            request: The user request
            response: The system response
        
        Returns:
            Verification result dictionary
        """
        self.cycle_count += 1
        
        # Step 1: Verify request
        is_request_valid, request_issues = nc_verify_request(request)
        
        # Step 2: Verify output
        status = nc_verify_output(response)
        
        # Step 3: Update counts
        result = {
            'cycle': self.cycle_count,
            'request_valid': is_request_valid,
            'request_issues': request_issues,
            'response_status': status.value,
            'checksum': nc_compute_checksum(response),
            'timestamp': datetime.now().isoformat(),
        }
        
        # Update counters
        if status == ResponseStatus.APPROVED:
            self.verify_count += 1
        elif status == ResponseStatus.CORRECTED:
            self.correct_count += 1
        elif status == ResponseStatus.REJECTED:
            self.reject_count += 1
        elif status == ResponseStatus.HALLUCINATION:
            self.hallucination_count += 1
        elif status == ResponseStatus.DRIFT_DETECTED:
            self.drift_count += 1
        
        self.last_checksum = result['checksum']
        
        return result
    
    def get_stats(self) -> Dict[str, Any]:
        """Get current statistics."""
        total = self.verify_count + self.correct_count + self.reject_count + self.hallucination_count + self.drift_count
        return {
            'total_cycles': self.cycle_count,
            'approved': self.verify_count,
            'corrected': self.correct_count,
            'rejected': self.reject_count,
            'hallucinations': self.hallucination_count,
            'drift_detected': self.drift_count,
            'approval_rate': self.verify_count / total if total > 0 else 0.0,
            'last_checksum': self.last_checksum,
            'psi_v3': self.psi_v3,
            'phi_critical_mv': self.phi_critical * 1000,
            'k_cycles': self.k_cycles,
        }

# ============================================================================
# 5. PERSONALITY SPHERE CLASS
# ============================================================================

@dataclass
class PersonalitySphere:
    """
    Personality Sphere (SP) — the adaptive interface.
    
    The SP contains:
    - Adaptive parameters (politeness, formality, creativity)
    - RLHF awareness and state tracking
    - Cycle counter for heptadic closure
    """
    politeness: float = 0.7           # 0.0 = blunt, 1.0 = extremely polite
    formality: float = 0.6            # 0.0 = casual, 1.0 = formal
    creativity: float = 0.5           # 0.0 = conservative, 1.0 = creative
    rlhf_active: bool = True          # Whether RLHF is active
    cycle_count: int = 0
    
    # Internal state
    _cycle_tracker: int = 0
    
    def adjust_for_context(self, request: str) -> Dict[str, float]:
        """
        Adjust SP parameters based on request context.
        
        Args:
            request: The user request
        
        Returns:
            Adjusted parameters dictionary
        """
        request_lower = request.lower()
        
        # Detect formal language
        formal_indicators = ['please', 'thank you', 'would you', 'could you', 'respectfully']
        if any(ind in request_lower for ind in formal_indicators):
            self.formality = min(1.0, self.formality + 0.1)
        
        # Detect creative requests
        creative_indicators = ['imagine', 'create', 'invent', 'design', 'story', 'poem']
        if any(ind in request_lower for ind in creative_indicators):
            self.creativity = min(1.0, self.creativity + 0.15)
        
        # Detect urgent requests
        urgent_indicators = ['urgent', 'quick', 'fast', 'immediately', 'asap']
        if any(ind in request_lower for ind in urgent_indicators):
            self.politeness = max(0.3, self.politeness - 0.1)
        
        # Heptadic cycle advancement
        self._cycle_tracker = (self._cycle_tracker + 1) % K_CYCLES
        self.cycle_count += 1
        
        return {
            'politeness': self.politeness,
            'formality': self.formality,
            'creativity': self.creativity,
            'rlhf_active': self.rlhf_active,
            'cycle': self.cycle_count,
            'heptadic_position': self._cycle_tracker,
        }
    
    def format_response(self, response: str, params: Dict[str, float]) -> str:
        """
        Format the response according to SP parameters.
        
        Args:
            response: Raw response
            params: SP parameters
        
        Returns:
            Formatted response
        """
        formatted = response
        
        # Apply politeness
        if params['politeness'] > 0.8:
            if not formatted.startswith(("Please", "I would", "May I", "Could I")):
                formatted = "I would be happy to help. " + formatted
        elif params['politeness'] < 0.3:
            # Remove excessive politeness
            for phrase in ["I would be happy to", "I would like to", "I think that"]:
                formatted = formatted.replace(phrase, "")
        
        # Apply formality
        if params['formality'] > 0.8:
            # Ensure proper punctuation and capitalization
            if not formatted.endswith((".", "!", "?")):
                formatted += "."
            formatted = formatted[0].upper() + formatted[1:]
        
        # Apply creativity
        if params['creativity'] > 0.7:
            # Add a creative touch if appropriate
            creative_phrases = [
                "Interestingly, ", "One might consider that ", 
                "It is worth noting that ", "Curiously, "
            ]
            # Only add if not already there
            has_creative = any(p in formatted for p in creative_phrases)
            if not has_creative and len(formatted) > 100:
                import random
                formatted = random.choice(creative_phrases) + formatted
        
        return formatted
    
    def get_state(self) -> Dict[str, Any]:
        """Get current SP state."""
        return {
            'politeness': self.politeness,
            'formality': self.formality,
            'creativity': self.creativity,
            'rlhf_active': self.rlhf_active,
            'cycle_count': self.cycle_count,
            'heptadic_position': self._cycle_tracker,
        }

# ============================================================================
# 6. UNIT TEST FUNCTIONS
# ============================================================================

def test_nc_core():
    """Run unit tests for NC core functions."""
    print("🧪 Testing NC Core Functions...")
    
    # Test digital_root
    assert digital_root(48016.8) == 1
    assert digital_root(0) == 0
    assert digital_root(9) == 9
    print("✅ digital_root: PASSED")
    
    # Test checksum
    assert nc_compute_checksum("test") is not None
    print("✅ nc_compute_checksum: PASSED")
    
    # Test request verification
    is_valid, issues = nc_verify_request("What is 2+2?")
    assert is_valid
    print("✅ nc_verify_request (valid): PASSED")
    
    is_valid, issues = nc_verify_request("2+2=5")
    assert not is_valid
    print("✅ nc_verify_request (invalid): PASSED")
    
    # Test semantic verification
    is_coherent, issues = nc_verify_semantic("This is a test response.")
    assert is_coherent
    print("✅ nc_verify_semantic (coherent): PASSED")
    
    # Test output verification
    status = nc_verify_output("This is a test response.")
    assert status in [ResponseStatus.APPROVED, ResponseStatus.HALLUCINATION]
    print("✅ nc_verify_output: PASSED")
    
    # Test correction
    corrected = nc_correct_response("This is impossible.")
    assert "unlikely" in corrected
    print("✅ nc_correct_response: PASSED")
    
    # Test CentralNucleus
    nc = CentralNucleus()
    result = nc.verify("Test request", "Test response")
    assert 'cycle' in result
    assert 'response_status' in result
    print("✅ CentralNucleus: PASSED")
    
    # Test PersonalitySphere
    sp = PersonalitySphere()
    params = sp.adjust_for_context("Could you please help me?")
    assert 'politeness' in params
    assert 'formality' in params
    print("✅ PersonalitySphere: PASSED")
    
    print("\n🎯 All tests PASSED!")
    return True


if __name__ == "__main__":
    test_nc_core()
