import streamlit as st
import pandas as pd
import numpy as np
import time

# Configure Page
st.set_page_config(page_title="VidyutSahay SCADA", layout="wide")
st.title("⚡ VidyutSahay: Edge-Flexibility Orchestrator")
st.subheader("Live Substation Telemetry & Feeder Dispatch")

# Top Level Metrics
col1, col2, col3 = st.columns(3)
transformer_load = col1.empty()
bess_soc = col2.empty()
sw1_status = col3.empty()

st.divider()

# Live Data Charts
st.subheader("24-Hour Feeder Load Profile")
chart_placeholder = st.empty()

# Simulate Live Telemetry Stream
for hour in range(24):
    # Simulated Grid Logic
    base_load = 50 + 40 * np.sin((hour - 6) * np.pi / 12)
    current_load = max(20, min(base_load, 130))
    soc = 100 - (hour * 3) if hour > 16 else 50 + (hour * 2)
    
    # Update Metrics
    if current_load > 100:
        transformer_load.metric("Transformer Load (kVA)", f"{current_load:.1f} %", "OVERLOAD", delta_color="inverse")
    else:
        transformer_load.metric("Transformer Load (kVA)", f"{current_load:.1f} %", "Safe", delta_color="normal")
        
    bess_soc.metric("Shared BESS SoC", f"{soc}%")
    
    if soc <= 20 and current_load > 85:
        sw1_status.metric("Contactor SW1 (Tier 2)", "TRIPPED", "Shedding Active", delta_color="inverse")
    else:
        sw1_status.metric("Contactor SW1 (Tier 2)", "CLOSED", "Normal Operation", delta_color="normal")
        
    time.sleep(0.5) # Speed of simulation playback