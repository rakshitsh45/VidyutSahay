%% =========================================================================
%% FILE: simulations/config/init_VidyutSahay.m
%% Master Parameter Initialization for MATLAB & Simulink
%% =========================================================================
clear; clc;

% 1. Grid & Transformer Electrical Constants
V_nom_LL = 415;                       % Secondary Line-to-Line RMS (V)
V_nom_LN = V_nom_LL / sqrt(3);        % Secondary Line-to-Neutral (~239.6 V)
f_grid = 50;                          % 50 Hz utility frequency
S_DT_rated = 250e3;                   % 250 kVA Distribution Transformer

% Transformer equivalent impedance parameters
R_DT = 0.015 * (V_nom_LL^2 / S_DT_rated); % 0.0103 Ohms
X_DT = 0.048 * (V_nom_LL^2 / S_DT_rated); % 0.0331 Ohms

% 2. 2nd-Life Battery Energy Storage System (BESS)
BESS_capacity_kWh = 100;              % 100 kWh repurposed pack
P_pcs_max = 40e3;                     % 40 kW bi-directional PCS rating
SoC_initial = 50;                     % Initial state of charge (%)
SoC_min_reserve = 20;                 % Reserve threshold triggering SW1
eta_bess = 0.92;                      % PCS/Battery round-trip efficiency

% 3. Statutory Feeder Operating Limits
V_max_statutory = 253;                % CEA upper voltage limit (V)
V_target = 230;                       % Target nominal bus voltage (V)

disp('VidyutSahay workspace parameters initialized successfully.');