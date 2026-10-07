import streamlit as st
import pandas as pd
import time

st.set_page_config(page_title="VidyutSahay SCADA", layout="wide")
st.title("⚡ VidyutSahay: Edge-Flexibility Orchestrator")

# Load real Simulink Data
@st.cache_data
def load_data():
    return pd.read_csv("dashboard/vidyutsahay_telemetry.csv")

df = load_data()

# Sidebar: Video Pitch Controls
st.sidebar.header("🎥 Video Pitch Controls")
st.sidebar.markdown("Use this to jump to emergency scenarios during your recording:")
scenario = st.sidebar.selectbox("Select Timeline Event:", [
    "1. Morning Startup (06:00)", 
    "2. Midday Solar Surplus (11:00)", 
    "3. Cloud Cover Drop (13:00)", 
    "4. Evening Peak Shaving (18:00)", 
    "5. Emergency Load Shedding (20:00)"
])
speed = st.sidebar.slider("Simulation Speed", 0.01, 0.5, 0.05)

# Map scenario selection to 24-hour time
start_time = 6.0
if "Surplus" in scenario: start_time = 11.0
elif "Cloud" in scenario: start_time = 13.0
elif "Peak" in scenario: start_time = 18.0
elif "Emergency" in scenario: start_time = 19.5

# Find the closest matching row in the CSV
start_idx = df[df['Time'] >= start_time].index[0] if not df[df['Time'] >= start_time].empty else 0

# UI Layout
col1, col2, col3 = st.columns(3)
load_metric = col1.empty()
soc_metric = col2.empty()
sw1_metric = col3.empty()
alert_box = st.empty()

st.subheader("Live Feeder Trend (24-Hour)")
chart = st.empty()

# Dynamic Playback Loop
step_size = max(1, len(df) // 400) # Sub-sample to keep the web browser smooth

for i in range(start_idx, len(df), step_size):
    row = df.iloc[i]
    
    # Update Top Metrics
    load_metric.metric("Transformer Load", f"{row['Transformer_Load']:.1f} A")
    soc_metric.metric("BESS SoC", f"{row['BESS_SoC']:.1f} %")
    
    # Evaluate Emergency Logic & Updates
    if row['SW1_Status'] >= 0.5:
        sw1_metric.metric("Contactor SW1 (Tier 2)", "TRIPPED", "Shedding Active", delta_color="inverse")
        alert_box.error("⚠️ EMERGENCY: BESS dropped below 20%. Tier 2 flexible loads paused. Tier 1 lifelines are 100% active.")
    else:
        sw1_metric.metric("Contactor SW1 (Tier 2)", "CLOSED", "Normal", delta_color="normal")
        if row['BESS_SoC'] > 95:
            alert_box.info("☀️ SOLAR SURPLUS: BESS charging at max capacity to prevent reverse voltage.")
        elif row['Transformer_Load'] > 85 and row['BESS_SoC'] < 50:
            alert_box.warning("⚡ PEAK SHAVING: High demand detected. BESS discharging to protect transformer.")
        else:
            alert_box.success("✅ GRID STABLE: Voltage and load within nominal limits.")
            
    # Draw expanding line chart
    current_data = df.iloc[:i+1:step_size]
    chart.line_chart(current_data.set_index('Time')[['Transformer_Load', 'BESS_SoC']])
    
    time.sleep(speed)