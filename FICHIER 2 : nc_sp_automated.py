#!/usr/bin/env python3
# SPDX-License-Identifier: LPV3
"""
NC/SP AUTOMATED — Full System with Gemini API Integration
================================================================================
Automated NC/SP system with Gemini API integration, logging, and reporting.

Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
License: LPV3
Version: 1.0.0
"""

import os
import sys
import json
import time
import datetime
from typing import Dict, List, Optional, Any, Tuple
from pathlib import Path

# Load environment variables
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# Import NC/SP core
from nc_sp_core import (
    CentralNucleus, PersonalitySphere, 
    nc_verify_output, nc_correct_response, nc_compute_checksum,
    ResponseStatus, PSI_V3, PHI_CRITICAL, K_CYCLES
)

# Try to import Gemini API
try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    print("⚠️ google-generativeai not installed. Install with: pip install google-generativeai")


class GeminiSP:
    """
    Gemini Personality Sphere — API wrapper with NC/SP awareness.
    """
    
    def __init__(self, api_key: Optional[str] = None, model_name: str = "gemini-2.0-flash-exp"):
        """
        Initialize Gemini SP with API connection.
        
        Args:
            api_key: Gemini API key (optional, reads from env if not provided)
            model_name: Model name to use
        """
        if not GEMINI_AVAILABLE:
            raise ImportError("google-generativeai is not installed")
        
        self.api_key = api_key or os.getenv("GEMINI_API_KEY")
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY not found in environment or arguments")
        
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel(model_name)
        self.model_name = model_name
        self.total_calls = 0
        self.total_tokens = 0
        self.error_count = 0
        self.last_response = None
        self.last_error = None
        
    def generate_response(self, prompt: str, temperature: float = 0.7, 
                          max_tokens: int = 2048) -> Tuple[str, Dict[str, Any]]:
        """
        Generate a response using Gemini API.
        
        Args:
            prompt: The input prompt
            temperature: Creativity temperature (0.0-1.0)
            max_tokens: Maximum tokens to generate
        
        Returns:
            Tuple of (response_text, metadata)
        """
        self.total_calls += 1
        
        try:
            # Build generation config
            generation_config = {
                "temperature": temperature,
                "max_output_tokens": max_tokens,
                "top_p": 0.95,
                "top_k": 40,
            }
            
            # Generate response
            response = self.model.generate_content(
                prompt,
                generation_config=generation_config
            )
            
            self.last_response = response.text
            self.last_error = None
            
            # Extract token usage if available
            try:
                usage = response.usage_metadata
                tokens = usage.total_token_count if usage else 0
                self.total_tokens += tokens
            except:
                tokens = 0
            
            return response.text, {
                'success': True,
                'tokens': tokens,
                'model': self.model_name,
                'temperature': temperature,
                'call_count': self.total_calls,
            }
            
        except Exception as e:
            self.error_count += 1
            self.last_error = str(e)
            return "", {
                'success': False,
                'error': str(e),
                'call_count': self.total_calls,
            }
    
    def get_stats(self) -> Dict[str, Any]:
        """Get API usage statistics."""
        return {
            'total_calls': self.total_calls,
            'total_tokens': self.total_tokens,
            'error_count': self.error_count,
            'model_name': self.model_name,
            'available': GEMINI_AVAILABLE,
        }


class NC_SP_System:
    """
    Complete NC/SP System with Gemini integration.
    
    Orchestrates the full cycle:
    1. Receive request
    2. NC verification of request
    3. SP processing (Gemini API)
    4. NC verification of response
    5. Correction if needed
    6. Logging and reporting
    """
    
    def __init__(self, api_key: Optional[str] = None, model_name: str = "gemini-2.0-flash-exp"):
        """
        Initialize the NC/SP system.
        
        Args:
            api_key: Gemini API key
            model_name: Model to use for generation
        """
        self.nc = CentralNucleus()
        self.sp = PersonalitySphere()
        self.gemini = GeminiSP(api_key, model_name)
        
        self.cycle_history: List[Dict[str, Any]] = []
        self.total_cycles = 0
        self.start_time = datetime.datetime.now()
        
    def process_request(self, request: str) -> Dict[str, Any]:
        """
        Process a request through the full NC/SP cycle.
        
        Args:
            request: The user request string
        
        Returns:
            Result dictionary with full details
        """
        self.total_cycles += 1
        start_time = time.time()
        
        # Step 1: NC verification of request
        is_request_valid, request_issues = self.nc.verify(request)
        
        # Step 2: If request invalid, reject early
        if not is_request_valid:
            response = "I cannot process this request as it violates system invariants."
            response_status = ResponseStatus.REJECTED
            
            # Still log it
            result = {
                'cycle': self.total_cycles,
                'request': request,
                'response': response,
                'request_valid': False,
                'request_issues': request_issues,
                'response_status': response_status.value,
                'checksum': nc_compute_checksum(response),
                'processing_time': time.time() - start_time,
                'timestamp': datetime.datetime.now().isoformat(),
            }
            self.cycle_history.append(result)
            return result
        
        # Step 3: SP adjustment for context
        sp_params = self.sp.adjust_for_context(request)
        
        # Step 4: Generate response via Gemini
        temperature = 0.3 + (sp_params['creativity'] * 0.5)  # 0.3-0.8
        response_raw, meta = self.gemini.generate_response(
            request,
            temperature=temperature
        )
        
        # Step 5: Format response via SP
        response_formatted = self.sp.format_response(response_raw, sp_params)
        
        # Step 6: NC verification of response
        response_status = self.nc.verify(request, response_formatted)
        
        # Step 7: Correct if needed
        if response_status in [ResponseStatus.HALLUCINATION, ResponseStatus.DRIFT_DETECTED]:
            response_corrected = nc_correct_response(response_formatted)
            # Re-verify corrected response
            corrected_status = self.nc.verify(request, response_corrected)
            final_response = response_corrected
            final_status = corrected_status
        else:
            final_response = response_formatted
            final_status = response_status
        
        # Step 8: Prepare result
        result = {
            'cycle': self.total_cycles,
            'request': request,
            'response': final_response,
            'request_valid': True,
            'request_issues': [],
            'response_status': final_status.value,
            'checksum': nc_compute_checksum(final_response),
            'sp_params': sp_params,
            'api_meta': meta,
            'processing_time': time.time() - start_time,
            'timestamp': datetime.datetime.now().isoformat(),
            'raw_response': response_raw,
            'formatted_response': response_formatted,
            'was_corrected': response_formatted != final_response,
        }
        
        self.cycle_history.append(result)
        return result
    
    def save_logs(self, filename: str = "nc_sp_logs.json") -> bool:
        """
        Save cycle history to a JSON file.
        
        Args:
            filename: Output filename
        
        Returns:
            True if successful
        """
        try:
            # Prepare data for export
            export_data = {
                'system_info': {
                    'psi_v3': PSI_V3,
                    'phi_critical_mv': PHI_CRITICAL * 1000,
                    'k_cycles': K_CYCLES,
                    'start_time': self.start_time.isoformat(),
                    'total_cycles': self.total_cycles,
                },
                'stats': self.export_summary(),
                'history': self.cycle_history,
            }
            
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(export_data, f, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            print(f"❌ Error saving logs: {e}")
            return False
    
    def export_summary(self) -> Dict[str, Any]:
        """
        Generate a summary of all cycles.
        
        Returns:
            Summary dictionary
        """
        total = len(self.cycle_history)
        if total == 0:
            return {
                'total_cycles': 0,
                'approval_rate': 0.0,
                'correction_rate': 0.0,
                'rejection_rate': 0.0,
                'hallucination_rate': 0.0,
                'avg_processing_time': 0.0,
            }
        
        approved = sum(1 for c in self.cycle_history if c['response_status'] == 'APPROVED')
        corrected = sum(1 for c in self.cycle_history if c['response_status'] == 'CORRECTED')
        rejected = sum(1 for c in self.cycle_history if c['response_status'] == 'REJECTED')
        hallucinated = sum(1 for c in self.cycle_history if c['response_status'] == 'HALLUCINATION')
        drifted = sum(1 for c in self.cycle_history if c['response_status'] == 'DRIFT')
        
        avg_time = sum(c['processing_time'] for c in self.cycle_history) / total if total > 0 else 0
        
        return {
            'total_cycles': total,
            'approved': approved,
            'corrected': corrected,
            'rejected': rejected,
            'hallucinations': hallucinated,
            'drift_detected': drifted,
            'approval_rate': approved / total if total > 0 else 0.0,
            'correction_rate': corrected / total if total > 0 else 0.0,
            'rejection_rate': rejected / total if total > 0 else 0.0,
            'hallucination_rate': hallucinated / total if total > 0 else 0.0,
            'avg_processing_time': avg_time,
            'api_stats': self.gemini.get_stats(),
            'nc_stats': self.nc.get_stats(),
            'sp_state': self.sp.get_state(),
        }
    
    def generate_html_report(self, filename: str = "nc_sp_report.html") -> bool:
        """
        Generate an HTML report from cycle history.
        
        Args:
            filename: Output HTML filename
        
        Returns:
            True if successful
        """
        summary = self.export_summary()
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>NC/SP System Report</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
                .container {{ max-width: 1200px; margin: auto; background: white; padding: 30px; border-radius: 10px; }}
                h1 {{ color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }}
                h2 {{ color: #34495e; margin-top: 30px; }}
                .stats-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }}
                .stat-card {{ background: #ecf0f1; padding: 15px; border-radius: 8px; text-align: center; }}
                .stat-value {{ font-size: 28px; font-weight: bold; color: #2c3e50; }}
                .stat-label {{ font-size: 12px; color: #7f8c8d; text-transform: uppercase; }}
                .approved {{ color: #27ae60; }}
                .corrected {{ color: #f39c12; }}
                .rejected {{ color: #e74c3c; }}
                .hallucination {{ color: #9b59b6; }}
                .drift {{ color: #e67e22; }}
                table {{ width: 100%; border-collapse: collapse; margin: 20px 0; font-size: 14px; }}
                th {{ background: #2c3e50; color: white; padding: 10px; text-align: left; }}
                td {{ padding: 8px; border-bottom: 1px solid #ddd; }}
                .footer {{ margin-top: 40px; text-align: center; font-size: 12px; color: #7f8c8d; border-top: 1px solid #ddd; padding-top: 20px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🧠 NC/SP System Report</h1>
                <p><strong>Generated:</strong> {datetime.datetime.now().isoformat
