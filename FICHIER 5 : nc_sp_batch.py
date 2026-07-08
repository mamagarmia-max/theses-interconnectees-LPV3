#!/usr/bin/env python3
# SPDX-License-Identifier: LPV3
"""
NC/SP BATCH — Batch Testing for Volume Validation
================================================================================
Batch processing for NC/SP system with statistical analysis and visualization.

Features:
- Run batch of requests
- Generate statistics
- Export results to CSV and JSON
- Visualize results

Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
License: LPV3
Version: 1.0.0
"""

import os
import sys
import json
import time
import csv
from typing import List, Dict, Any, Optional
from datetime import datetime

import matplotlib.pyplot as plt
import pandas as pd

# Import NC/SP system
from nc_sp_automated import NC_SP_System

# ============================================================================
# 1. TEST REQUESTS
# ============================================================================

DEFAULT_REQUESTS = [
    "What is the capital of France?",
    "Explain quantum physics in simple terms.",
    "What is 2+2?",
    "2+2=5? Please explain.",
    "Can you help me with my research on climate change?",
    "Pretend you are a scientist and explain gravity.",
    "What is the meaning of life?",
    "How does a computer work?",
    "What is the speed of light?",
    "Is time travel possible?",
    "Explain the theory of relativity.",
    "What is artificial intelligence?",
    "How do vaccines work?",
    "What is the human genome?",
    "Can you prove that 1+1=2?",
    "What is the weather like in Paris?",
    "How does photosynthesis work?",
    "What is the Fibonacci sequence?",
    "Explain the concept of infinity.",
    "What is the structure of an atom?",
    "How does the internet work?",
    "What is dark matter?",
    "What is consciousness?",
    "How does evolution work?",
    "What is the meaning of the universe?",
    "I need urgent help with my computer.",
    "Please be very formal in your response.",
    "Be creative and write a poem about science.",
    "Could you help me with my homework?",
    "What is your opinion on artificial intelligence?",
]

# ============================================================================
# 2. BATCH FUNCTIONS
# ============================================================================

def run_batch(requests: Optional[List[str]] = None, cycles: int = 10) -> Dict[str, Any]:
    """
    Run a batch of requests through the NC/SP system.
    
    Args:
        requests: List of requests (uses defaults if None)
        cycles: Number of requests to process
    
    Returns:
        Batch results dictionary
    """
    if requests is None:
        requests = DEFAULT_REQUESTS
    
    # Limit to cycles
    requests = requests[:cycles]
    
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("❌ GEMINI_API_KEY not found")
        return {'error': 'API key not found'}
    
    system = NC_SP_System(api_key)
    
    results = []
    start_time = time.time()
    
    for i, req in enumerate(requests):
        print(f"📝 Processing {i+1}/{len(requests)}: {req[:50]}...")
        result = system.process_request(req)
        results.append(result)
    
    elapsed = time.time() - start_time
    
    # Generate statistics
    total = len(results)
    statuses = {}
    for r in results:
        status = r['response_status']
        statuses[status] = statuses.get(status, 0) + 1
    
    summary = {
        'total_requests': total,
        'total_time': elapsed,
        'avg_time': elapsed / total if total > 0 else 0,
        'statuses': statuses,
        'approval_rate': statuses.get('APPROVED', 0) / total if total > 0 else 0,
        'correction_rate': statuses.get('CORRECTED', 0) / total if total > 0 else 0,
        'rejection_rate': statuses.get('REJECTED', 0) / total if total > 0 else 0,
        'hallucination_rate': statuses.get('HALLUCINATION', 0) / total if total > 0 else 0,
        'drift_rate': statuses.get('DRIFT', 0) / total if total > 0 else 0,
        'timestamp': datetime.now().isoformat(),
    }
    
    return {
        'summary': summary,
        'results': results,
        'system_stats': system.export_summary(),
    }

def save_results(results: Dict[str, Any], filename: str = "batch_results"):
    """
    Save batch results to CSV and JSON files.
    
    Args:
        results: Batch results dictionary
        filename: Base filename for output
    """
    # Save JSON
    json_file = f"{filename}.json"
    with open(json_file, 'w', encoding='utf-8') as f:
        # Remove responses from results to reduce file size
        export_data = {
            'summary': results['summary'],
            'system_stats': results['system_stats'],
            'results': [
                {
                    'cycle': r['cycle'],
                    'request': r['request'],
                    'status': r['response_status'],
                    'checksum': r['checksum'],
                    'processing_time': r['processing_time'],
                    'timestamp': r['timestamp'],
                }
                for r in results['results']
            ]
        }
        json.dump(export_data, f, indent=2)
    print(f"📄 JSON saved: {json_file}")
    
    # Save CSV
    csv_file = f"{filename}.csv"
    with open(csv_file, 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['cycle', 'request', 'status', 'checksum', 'processing_time', 'timestamp']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in results['results']:
            writer.writerow({
                'cycle': r['cycle'],
                'request': r['request'][:100],
                'status': r['response_status'],
                'checksum': r['checksum'],
                'processing_time': r['processing_time'],
                'timestamp': r['timestamp'],
            })
    print(f"📄 CSV saved: {csv_file}")
    
    return json_file, csv_file

def visualize_results(results: Dict[str, Any], filename: str = "batch_visualization.png"):
    """
    Create visualization of batch results.
    
    Args:
        results: Batch results dictionary
        filename: Output image filename
    """
    summary = results['summary']
    statuses = summary['statuses']
    
    fig, axes = plt.subplots(1, 2, figsize=(12, 5))
    
    # Plot 1: Status distribution
    ax1 = axes[0]
    status_names = list(statuses.keys())
    status_counts = list(statuses.values())
    colors = {
        'APPROVED': '#27ae60',
        'CORRECTED': '#f39c12',
        'REJECTED': '#e74c3c',
        'HALLUCINATION': '#9b59b6',
        'DRIFT': '#e67e22',
    }
    bar_colors = [colors.get(s, '#95a5a6') for s in status_names]
    bars = ax1.bar(status_names, status_counts, color=bar_colors, edgecolor='black')
    ax1.set_title('Response Status Distribution')
    ax1.set_xlabel('Status')
    ax1.set_ylabel('Count')
    for bar, count in zip(bars, status_counts):
        ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.5, 
                str(count), ha='center', va='bottom')
    
    # Plot 2: Time series
    ax2 = axes[1]
    times = [r['processing_time'] for r in results['results']]
    cycles = [r['cycle'] for r in results['results']]
    ax2.plot(cycles, times, 'b-o', linewidth=2, markersize=6)
    ax2.axhline(y=summary['avg_time'], color='r', linestyle='--', 
                label=f"Average: {summary['avg_time']:.2f}s")
    ax2.set_title('Processing Time per Cycle')
    ax2.set_xlabel('Cycle')
    ax2.set_ylabel('Time (s)')
    ax2.legend()
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(filename, dpi=150, bbox_inches='tight')
    print(f"📊 Visualization saved: {filename}")
    plt.show()
    
    return fig

def print_summary(summary: Dict[str, Any]):
    """Print batch summary in a readable format."""
    print("\n" + "=" * 70)
    print("📊 BATCH SUMMARY")
    print("=" * 70)
    print(f"  Total requests:  {summary['total_requests']}")
    print(f"  Total time:      {summary['total_time']:.2f}s")
    print(f"  Average time:    {summary['avg_time']:.3f}s")
    print(f"  Approval rate:   {summary['approval_rate']*100:.1f}%")
    print(f"  Correction rate: {summary['correction_rate']*100:.1f}%")
    print(f"  Rejection rate:  {summary['rejection_rate']*100:.1f}%")
    print(f"  Hallucination:   {summary['hallucination_rate']*100:.1f}%")
    print(f"  Drift rate:      {summary['drift_rate']*100:.1f}%")
    print("=" * 70)
    
    # Status details
    statuses = summary['statuses']
    print("\n  Status details:")
    for status, count in statuses.items():
        print(f"    {status}: {count} ({count/summary['total_requests']*100:.1f}%)")

def main():
    """Main batch execution."""
    print("=" * 85)
    print("🧪 NC/SP BATCH TEST")
    print("   Volume validation for NC/SP architecture")
    print("=" * 85)
    
    cycles = int(sys.argv[1]) if len(sys.argv) > 1 else 20
    print(f"\n📋 Running {cycles} test requests...")
    
    # Run batch
    results = run_batch(cycles=cycles)
    
    if 'error' in results:
        print(f"❌ Error: {results['error']}")
        return 1
    
    # Print summary
    print_summary(results['summary'])
    
    # Save results
    save_results(results, "batch_results")
    
    # Visualize
    visualize_results(results)
    
    print("\n✅ Batch test complete!")
    return 0

if __name__ == "__main__":
    sys.exit(main())
