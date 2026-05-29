fNIRS_PMI
A reproducible end-to-end workflow for a real-time fNIRS neurofeedback experiment targeting emotion regulation, including an offline analysis pipeline for statistical evaluation and visualization.
This repository accompanies the manuscript:
“Targeting emotion regulation with fNIRS neurofeedback training – a feasibility study in healthy participants”
It integrates all components required for:
Data acquisition
Real-time neurofeedback
Offline preprocessing
GLM-based statistical analysis
Visualization and figure generation
1. Project Overview
The project is organized into two main modules:
online-scripts-main/ → real-time experiment pipeline
offline-scripts-main/ → offline analysis pipeline
1.1 Online Pipeline (Real-time Experiment)
The online-scripts-main/ directory includes scripts for:
Experimental presentation
Data acquisition
Neurofeedback computation
Threshold estimation
Helper functions (GLM, preprocessing utilities, visualization parameters)
Main scripts
EXP_00_FAMILIARIZATION_RUN.m
PMI_EXP_01_LOCALIZER.m
PMI_EXP_02_NFB_PREPARATION.m
PMI_EXP_03_NFB.m
1.2 Offline Pipeline (Analysis)
The offline-scripts-main/ directory contains scripts for:
Signal preprocessing
GLM analysis
Statistical evaluation
Visualization
Entry-point scripts
TSI_Data_Analysis_loc.m
TSI_Data_Analysis_NFB.m
These scripts:
Process Turbo-Satori (TSI) outputs
Perform GLM analysis using NIRS Brain AnalyzIR Toolbox
Export beta values for statistical testing
2. Repository Structure
fNIRS_PMI/
├── online-scripts-main/
│   ├── EXP_00_FAMILIARIZATION_RUN.m
│   ├── PMI_EXP_01_LOCALIZER.m
│   ├── PMI_EXP_02_NFB_PREPARATION.m
│   ├── PMI_EXP_03_NFB.m
│   └── helper_functions/
│
└── offline-scripts-main/
    ├── data/
    │   ├── Raw/
    │   │   ├── Localizer/
    │   │   └── NFB/
    │   │
    │   └── online_processed_TSI_data/
    │       ├── Localizer/
    │       └── NFB/
    │
    ├── lib_tsi/
    ├── plotting_tsi/
    ├── paper_figures_code/
    ├── paper_figures_data/
    ├── Questionnaires/
    ├── statistical_analysis_with_Jamovi/
    ├── post-processed_tsi_data/
    ├── TSI_Data_Analysis_loc.m
    └── TSI_Data_Analysis_NFB.m
3. Software Requirements
The workflow was implemented across two systems.
3.1 Laptop A — Acquisition & Offline Analysis
Used for:
fNIRS acquisition
Neurofeedback preparation
Offline analysis
Software:
Aurora 2023.9 (NIRSport 2)
MATLAB R2021b
NIRS Brain AnalyzIR Toolbox
Optional: QT-NIRS Toolbox
Windows 10
3.2 Laptop B — Experiment & Real-time Processing
Used for:
Localizer task
Neurofeedback task
Real-time signal processing
Software:
Turbo-Satori 2.0 (TSI)
Psychtoolbox-3
MATLAB R2018a
Windows 10
4. Data Acquisition Workflow
fNIRS data were acquired using NIRSport 2 and Aurora software.
4.1 System Setup
NIRSport 2 connected to Laptop A (Aurora control)
Ethernet connection between Laptop A and Laptop B for real-time streaming
4.2 Experimental Stages
1. Localizer
Script: PMI_EXP_01_LOCALIZER.m
Raw data stored in: data/Raw/Localizer/
TSI outputs stored in: data/online_processed_TSI_data/Localizer/
2. Neurofeedback Preparation
Script: PMI_EXP_02_NFB_PREPARATION.m
Computes:
Subject-specific thresholds
Optimal 3 neurofeedback channels
3. Neurofeedback Training
Script: PMI_EXP_03_NFB.m
Uses:
Precomputed thresholds
Selected channels
Records:
HbO / HbR signals
Feedback states
Threshold dynamics
5. Offline Analysis Pipeline
Offline analysis uses:
TSI_Data_Analysis_loc.m
TSI_Data_Analysis_NFB.m
NIRS Brain AnalyzIR Toolbox
5.1 Preprocessing Steps
Conversion to HbO / HbR
Standardization across participants
Intermediate outputs:
preprocessing_PMI_localizer_offline.mat
preprocessing_PMI_NFB_offline.mat
5.2 GLM Analysis
Produces:
GLM_PMI_offline.mat
Stored in:
offline-scripts-main/post-processed_tsi_data/
6. Beta Extraction & Statistical Analysis
6.1 Beta Extraction
Script:
extract_betas.m
Outputs:
hbr_betas_average_NFB_channs.xlsx
hbo_betas_average_NFB_channs.xlsx
Location:
offline-scripts-main/paper_figures_data/
6.2 Figure Generation Scripts
Figure 3A & 3B
plot_betas_and_controlability_measures_fig3a_b.m
Uses:
beta values
subjective controllability questionnaire
Figure 4
cor_loc_nfb_fig4.m
Computes Spearman correlation between Localizer and NFB betas
Figure 3C
plot_percentage_of_ratios_fig3c.m
Uses:
table_ratios_S1.mat
table_ratios_S2.mat
table_ratios_S3.mat
Ratio Computation
table_ratios_run_level_NFBchans.m
Reconstructs real-time signal-to-threshold logic
Additional Analysis Scripts
cerq_descriptives_statistics.m
erq_descriptives_statistics.m
ders_descriptives_statistics.m
pre_post_coordinates_stormnet.m
ratios_6seconds_after_task_participant_run_level.m
