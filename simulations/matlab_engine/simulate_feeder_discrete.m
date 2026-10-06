%% =========================================================================
%% FILE: simulations/matlab_engine/simulate_feeder_discrete.m
%% VidyutSahay: 24-Hour Distribution Feeder & Edge Control Simulation
%% =========================================================================
clear; clc; close all;

% 1. Load Master Parameters
run('../config/init_VidyutSahay.m');

% 2. Time Vector (24 hours, 1-minute steps)
dt_hours = 1/60;
t = 0:dt_hours:24;
N = length(t);

% 3. Demand & Solar Profiles
P_tier1 = 20e3 + 5e3 * sin(2*pi*(t - 7)/24);       % Critical baseline
P_tier2_nominal = 35e3 + 25e3 * sin(2*pi*(t - 14)/24); 
P_tier2_nominal(P_tier2_nominal < 10e3) = 10e3;    % Flexible evening peak

P_solar = zeros(1, N);
daylight = (t >= 6.5 & t <= 18.0);
P_solar(daylight) = 95e3 * sin(pi * (t(daylight) - 6.5) / 11.5);
cloud_idx = (t >= 13.20 & t <= 13.45);
P_solar(cloud_idx) = P_solar(cloud_idx) * 0.20;    % 80% sudden cloud drop

% 4. State Variables
V_bus_LN = zeros(1, N);
DT_loading = zeros(1, N);
SoC = zeros(1, N);
SW1_status = ones(1, N);
curr_soc = SoC_initial;

% 5. Simulation Loop
for k = 1:N
    P_net_raw = P_tier1(k) + P_tier2_nominal(k) - P_solar(k);
    P_cmd = 0;

    % Edge Control Rules
    if P_net_raw < 0 && curr_soc < 98
        P_cmd = max(-abs(P_net_raw), -P_pcs_max); % Absorb noon solar
    elseif (P_net_raw > 0.65 * S_DT_rated) || (cloud_idx(k) && curr_soc > SoC_min_reserve)
        P_deficit = P_net_raw - 0.60 * S_DT_rated;
        P_cmd = min(max(P_deficit, 25e3), P_pcs_max); % Inject active power
    end

    % Tier 2 Shedding (SW1) Logic
    if (curr_soc <= SoC_min_reserve) && (P_net_raw > 0.70 * S_DT_rated)
        SW1_status(k) = 0; % Trip
    else
        SW1_status(k) = 1; % Close
    end

    % Actual Grid Math
    P_actual = P_tier1(k) + (SW1_status(k) * P_tier2_nominal(k));
    P_DT = P_actual - P_solar(k) - P_cmd;

    % Battery SoC Update
    if P_cmd < 0
        curr_soc = curr_soc - (P_cmd * eta_bess * dt_hours / (BESS_capacity_kWh * 1000)) * 100;
    else
        curr_soc = curr_soc - (P_cmd / eta_bess * dt_hours / (BESS_capacity_kWh * 1000)) * 100;
    end
    SoC(k) = curr_soc;

    % Voltage and Load Math
    V_bus_LN(k) = V_nom_LN - (P_DT * R_DT) / V_nom_LN;
    DT_loading(k) = (abs(P_DT) / S_DT_rated) * 100;
end

% 6. Plotting
figure('Name', 'VidyutSahay Results', 'Color', 'w', 'Position', [100, 100, 900, 700]);
subplot(4,1,1); plot(t, V_bus_LN, 'LineWidth', 1.5); hold on;
yline(V_max_statutory, '--r', 'Limit (253V)'); ylabel('Voltage (V)'); grid on; title('Feeder Voltage Regulation');

subplot(4,1,2); plot(t, DT_loading, 'LineWidth', 1.5, 'Color', '#D95319'); hold on;
yline(100, '--r', '100% Load'); ylabel('DT Load (%)'); grid on; title('Transformer Thermal Loading');

subplot(4,1,3); plot(t, SoC, 'LineWidth', 1.5, 'Color', '#77AC30'); hold on;
yline(SoC_min_reserve, '--m', '20% Reserve'); ylabel('SoC (%)'); grid on; title('2nd-Life BESS State of Charge');

subplot(4,1,4); stairs(t, SW1_status, 'LineWidth', 1.5, 'Color', '#7E2F8E'); ylim([-0.2 1.2]);
yticks([0 1]); yticklabels({'TRIPPED', 'CLOSED'}); ylabel('SW1 State'); xlabel('Hour of Day'); grid on; title('Contactor SW1 Status');