#!/usr/bin/env python3
# SPDX-License-Identifier: LPV3
"""
NC/SP API — REST API for Remote Integration
================================================================================
FastAPI implementation for NC/SP system with REST endpoints.

Endpoints:
- POST /process: Process a request through NC/SP cycle
- GET /health: System health check
- GET /stats: System statistics
- GET /logs: Cycle history

Author: Dr. Benhadid Outail (ORCID: 0009-0003-3057-9543)
License: LPV3
Version: 1.0.0
"""

import os
import sys
import json
from typing import Optional, List, Dict, Any
from datetime import datetime
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import uvicorn

# Import NC/SP system
from nc_sp_automated import NC_SP_System

# ============================================================================
# 1. PYDANTIC MODELS
# ============================================================================

class ProcessRequest(BaseModel):
    """Request model for /process endpoint."""
    request: str = Field(..., description="User request to process", min_length=1, max_length=10000)
    temperature: Optional[float] = Field(0.7, ge=0.0, le=1.0, description="Creativity temperature")
    max_tokens: Optional[int] = Field(2048, ge=1, le=8192, description="Maximum tokens to generate")

class ProcessResponse(BaseModel):
    """Response model for /process endpoint."""
    cycle: int
    request: str
    response: str
    status: str
    checksum: int
    processing_time: float
    timestamp: str
    was_corrected: bool = False

class HealthResponse(BaseModel):
    """Response model for /health endpoint."""
    status: str
    version: str
    uptime: str
    psi_v3: float
    phi_critical_mv: float
    k_cycles: int

class StatsResponse(BaseModel):
    """Response model for /stats endpoint."""
    total_cycles: int
    approved: int
    corrected: int
    rejected: int
    hallucinations: int
    drift_detected: int
    approval_rate: float
    correction_rate: float
    rejection_rate: float
    hallucination_rate: float
    avg_processing_time: float
    api_total_calls: int
    api_total_tokens: int
    api_error_count: int

class LogEntry(BaseModel):
    """Model for a single log entry."""
    cycle: int
    request: str
    response: str
    status: str
    checksum: int
    processing_time: float
    timestamp: str

class LogsResponse(BaseModel):
    """Response model for /logs endpoint."""
    total: int
    logs: List[LogEntry]

# ============================================================================
# 2. SYSTEM STATE
# ============================================================================

system: Optional[NC_SP_System] = None
start_time: datetime = datetime.now()

def get_system() -> NC_SP_System:
    """Get or initialize the NC/SP system."""
    global system
    if system is None:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise RuntimeError("GEMINI_API_KEY not set")
        system = NC_SP_System(api_key)
    return system

# ============================================================================
# 3. FASTAPI APP
# ============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan management."""
    print("🧠 NC/SP API starting...")
    try:
        get_system()
        print("✅ NC/SP system initialized")
    except Exception as e:
        print(f"⚠️ System initialized in simulation mode: {e}")
    yield
    print("🛑 NC/SP API shutting down...")

app = FastAPI(
    title="NC/SP API",
    description="Central Nucleus / Personality Sphere Architecture API",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================================
# 4. ENDPOINTS
# ============================================================================

@app.post("/process", response_model=ProcessResponse)
async def process_request(req: ProcessRequest) -> ProcessResponse:
    """
    Process a request through the NC/SP cycle.
    
    Returns the validated and corrected response.
    """
    try:
        system = get_system()
        result = system.process_request(req.request)
        
        return ProcessResponse(
            cycle=result['cycle'],
            request=result['request'],
            response=result['response'],
            status=result['response_status'],
            checksum=result['checksum'],
            processing_time=result['processing_time'],
            timestamp=result['timestamp'],
            was_corrected=result.get('was_corrected', False)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """System health check endpoint."""
    uptime = datetime.now() - start_time
    return HealthResponse(
        status="healthy" if system is not None else "initializing",
        version="1.0.0",
        uptime=str(uptime).split('.')[0],
        psi_v3=48016.8,
        phi_critical_mv=-51.1,
        k_cycles=7
    )

@app.get("/stats", response_model=StatsResponse)
async def get_stats() -> StatsResponse:
    """Get system statistics."""
    try:
        system = get_system()
        summary = system.export_summary()
        
        return StatsResponse(
            total_cycles=summary['total_cycles'],
            approved=summary['approved'],
            corrected=summary['corrected'],
            rejected=summary['rejected'],
            hallucinations=summary['hallucinations'],
            drift_detected=summary['drift_detected'],
            approval_rate=summary['approval_rate'],
            correction_rate=summary['correction_rate'],
            rejection_rate=summary['rejection_rate'],
            hallucination_rate=summary['hallucination_rate'],
            avg_processing_time=summary['avg_processing_time'],
            api_total_calls=summary.get('api_stats', {}).get('total_calls', 0),
            api_total_tokens=summary.get('api_stats', {}).get('total_tokens', 0),
            api_error_count=summary.get('api_stats', {}).get('error_count', 0)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/logs", response_model=LogsResponse)
async def get_logs(limit: Optional[int] = 100) -> LogsResponse:
    """Get cycle history logs."""
    try:
        system = get_system()
        logs = system.get_logs()
        
        # Apply limit
        if limit and limit > 0:
            logs = logs[-limit:]
        
        log_entries = [
            LogEntry(
                cycle=log['cycle'],
                request=log['request'],
                response=log['response'][:500] + ("..." if len(log['response']) > 500 else ""),
                status=log['response_status'],
                checksum=log['checksum'],
                processing_time=log['processing_time'],
                timestamp=log['timestamp']
            )
            for log in logs
        ]
        
        return LogsResponse(
            total=len(log_entries),
            logs=log_entries
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    """Root endpoint with API documentation link."""
    return {
        "message": "NC/SP API",
        "documentation": "/docs",
        "version": "1.0.0"
    }

# ============================================================================
# 5. MAIN
# ============================================================================

def main():
    """Run the API server."""
    port = int(os.getenv("API_PORT", "8000"))
    host = os.getenv("API_HOST", "0.0.0.0")
    
    print("=" * 85)
    print("🧠 NC/SP API Server")
    print("   Version: 1.0.0")
    print("   Host: {}:{}".format(host, port))
    print("   Documentation: http://{}:{}/docs".format(host, port))
    print("=" * 85)
    
    uvicorn.run(
        "nc_sp_api:app",
        host=host,
        port=port,
        reload=False,
        log_level="info"
    )

if __name__ == "__main__":
    main()
