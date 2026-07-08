#!/usr/bin/env python3
# SPDX-License-Identifier: LPV3
"""
NC/SP STREAMLIT — Interactive Web Interface
================================================================================
Streamlit interface for NC/SP system with real-time interaction.

Features:
- Request input and processing
- Status visualization with colors
- Cycle history table
- Log export
- System statistics

Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
License: LPV3
Version: 1.0.0
"""

import os
import sys
import json
import time
import streamlit as st
import pandas as pd
from datetime import datetime

# Import NC/SP system
from nc_sp_automated import NC_SP_System

# ============================================================================
# 1. PAGE CONFIGURATION
# ============================================================================

st.set_page_config(
    page_title="NC/SP System",
    page_icon="🧠",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ============================================================================
# 2. STYLES
# ============================================================================

st.markdown("""
<style>
    .main-header { color: #2c3e50; font-size: 32px; font-weight: bold; }
    .sub-header { color: #34495e; font-size: 18px; margin-bottom: 20px; }
    .approved { color: #27ae60; font-weight: bold; }
    .corrected { color: #f39c12; font-weight: bold; }
    .rejected { color: #e74c3c; font-weight: bold; }
    .hallucination { color: #9b59b6; font-weight: bold; }
    .drift { color: #e67e22; font-weight: bold; }
    .status-box { padding: 10px; border-radius: 8px; margin: 10px 0; }
    .status-box-approved { background: #d5f5e3; border-left: 4px solid #27ae60; }
    .status-box-corrected { background: #fdebd0; border-left: 4px solid #f39c12; }
    .status-box-rejected { background: #fadbd8; border-left: 4px solid #e74c3c; }
    .status-box-hallucination { background: #ebdef0; border-left: 4px solid #9b59b6; }
    .status-box-drift { background: #fae5d3; border-left: 4px solid #e67e22; }
    .metric-card { background: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center; }
    .metric-value { font-size: 28px; font-weight: bold; color: #2c3e50; }
    .metric-label { font-size: 12px; color: #7f8c8d; text-transform: uppercase; }
    .footer { margin-top: 40px; text-align: center; font-size: 12px; color: #7f8c8d; border-top: 1px solid #ddd; padding-top: 20px; }
</style>
""", unsafe_allow_html=True)

# ============================================================================
# 3. INITIALIZATION
# ============================================================================

def init_system():
    """Initialize or get the NC/SP system from session state."""
    if 'system' not in st.session_state:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            st.warning("⚠️ GEMINI_API_KEY not found. Please set it in .env file.")
            st.session_state.system = None
        else:
            st.session_state.system = NC_SP_System(api_key)
    
    if 'history' not in st.session_state:
        st.session_state.history = []
    
    if 'processed_count' not in st.session_state:
        st.session_state.processed_count = 0

def get_status_color(status):
    """Get color class for a status."""
    colors = {
        'APPROVED': 'approved',
        'CORRECTED': 'corrected',
        'REJECTED': 'rejected',
        'HALLUCINATION': 'hallucination',
        'DRIFT': 'drift',
    }
    return colors.get(status, '')

def get_status_box(status):
    """Get status box class."""
    boxes = {
        'APPROVED': 'status-box-approved',
        'CORRECTED': 'status-box-corrected',
        'REJECTED': 'status-box-rejected',
        'HALLUCINATION': 'status-box-hallucination',
        'DRIFT': 'status-box-drift',
    }
    return boxes.get(status, '')

# ============================================================================
# 4. MAIN INTERFACE
# ============================================================================

def main():
    """Main Streamlit interface."""
    init_system()
    
    # Header
    st.markdown('<div class="main-header">🧠 NC/SP System</div>', unsafe_allow_html=True)
    st.markdown('<div class="sub-header">Central Nucleus / Personality Sphere Architecture</div>', unsafe_allow_html=True)
    
    # Sidebar
    with st.sidebar:
        st.markdown("### ⚙️ Configuration")
        
        api_key = st.text_input("Gemini API Key", type="password", 
                                value=os.getenv("GEMINI_API_KEY", ""))
        if api_key:
            os.environ["GEMINI_API_KEY"] = api_key
        
        st.markdown("---")
        st.markdown("### 📊 System Info")
        st.markdown(f"**Ψ_V₃:** 48,016.8 kg·m⁻²")
        st.markdown(f"**Φ_critical:** -51.1 mV")
        st.markdown(f"**k:** 7 (heptadic closure)")
        st.markdown(f"**Processed:** {st.session_state.processed_count}")
        
        st.markdown("---")
        st.markdown("### 💾 Export")
        if st.button("📥 Export Logs (JSON)"):
            if st.session_state.history:
                export_data = {
                    'timestamp': datetime.now().isoformat(),
                    'total': len(st.session_state.history),
                    'history': st.session_state.history
                }
                st.download_button(
                    "Download JSON",
                    data=json.dumps(export_data, indent=2),
                    file_name=f"nc_sp_logs_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                    mime="application/json"
                )
    
    # Main area
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.markdown("### 📝 Request")
        
        request = st.text_area(
            "Enter your request:",
            placeholder="What would you like to know?",
            height=100
        )
        
        col_btn1, col_btn2 = st.columns([1, 3])
        with col_btn1:
            process_btn = st.button("🚀 Process", type="primary")
        
        if process_btn and request:
            if st.session_state.system is None:
                st.error("❌ System not initialized. Please set API key.")
            else:
                with st.spinner("Processing through NC/SP cycle..."):
                    start_time = time.time()
                    result = st.session_state.system.process_request(request)
                    elapsed = time.time() - start_time
                    
                    st.session_state.history.append(result)
                    st.session_state.processed_count += 1
                    
                    # Display result
                    st.markdown("---")
                    st.markdown("### 📥 Response")
                    
                    status = result['response_status']
                    box_class = get_status_box(status)
                    color_class = get_status_color(status)
                    
                    st.markdown(f"""
                    <div class="status-box {box_class}">
                        <strong>Status:</strong> <span class="{color_class}">{status}</span><br>
                        <strong>Checksum:</strong> {result['checksum']}<br>
                        <strong>Time:</strong> {elapsed:.2f}s<br>
                        <strong>Cycle:</strong> {result['cycle']}
                    </div>
                    """, unsafe_allow_html=True)
                    
                    st.markdown(result['response'])
                    
                    if result.get('was_corrected', False):
                        st.info("🔄 Response was corrected by homeostasis.")
                    
                    if result.get('request_issues'):
                        st.warning(f"⚠️ Request issues: {', '.join(result['request_issues'])}")
    
    with col2:
        st.markdown("### 📊 Statistics")
        
        if st.session_state.history:
            history = st.session_state.history
            
            # Count statuses
            statuses = {}
            for h in history:
                status = h['response_status']
                statuses[status] = statuses.get(status, 0) + 1
            
            total = len(history)
            
            # Display metrics
            cols = st.columns(2)
            metrics = [
                ("Approved", statuses.get('APPROVED', 0), 'approved'),
                ("Corrected", statuses.get('CORRECTED', 0), 'corrected'),
                ("Rejected", statuses.get('REJECTED', 0), 'rejected'),
                ("Hallucinations", statuses.get('HALLUCINATION', 0), 'hallucination'),
                ("Drift", statuses.get('DRIFT', 0), 'drift'),
            ]
            
            for i, (label, value, cls) in enumerate(metrics):
                col = cols[i % 2]
                with col:
                    st.markdown(f"""
                    <div class="metric-card">
                        <div class="metric-label">{label}</div>
                        <div class="metric-value {cls}">{value}</div>
                        <div style="font-size:11px;color:#7f8c8d;">{value/total*100:.1f}%</div>
                    </div>
                    """, unsafe_allow_html=True)
            
            # History table
            st.markdown("---")
            st.markdown("### 📋 History")
            
            # Create dataframe
            df_data = []
            for h in history[-10:]:
                df_data.append({
                    'Cycle': h['cycle'],
                    'Request': h['request'][:50] + '...' if len(h['request']) > 50 else h['request'],
                    'Status': h['response_status'],
                    'Checksum': h['checksum'],
                    'Time': f"{h['processing_time']:.2f}s"
                })
            
            if df_data:
                df = pd.DataFrame(df_data)
                st.dataframe(df, use_container_width=True)
        else:
            st.info("No cycles processed yet. Enter a request above.")

    # Footer
    st.markdown("""
    <div class="footer">
        <p>NC/SP Architecture — Dr. Benhadid Outail</p>
        <p>Ψ_V₃ = 48,016.8 kg·m⁻² — locked.</p>
    </div>
    """, unsafe_allow_html=True)

if __name__ == "__main__":
    main()
