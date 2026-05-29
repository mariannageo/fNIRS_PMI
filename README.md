# A Reproducible Workflow for Real-Time fNIRS Neurofeedback for Emotion Regulation and Offline Analysis

This technical note presents a reproducible end-to-end workflow for a functional near-infrared spectroscopy (fNIRS) neurofeedback experiment targeting emotion regulation. The pipeline supports the feasibility study:

**“Targeting emotion regulation with fNIRS neurofeedback training – a feasibility study in healthy participants”**

It integrates all hardware and software components required for:
- data acquisition
- real-time processing
- offline analysis
- visualization

The workflow is designed to support reproducibility and adaptation to related fNIRS neurofeedback and affective neuroscience applications.

---

## 1. Project Organization

The project consists of two main modules:

- `online-scripts-main/` → real-time experimental pipeline  
- `offline-scripts-main/` → offline analysis pipeline  

The online module contains scripts for:
- experiment presentation
- data acquisition
- threshold computation
- neurofeedback delivery
- helper functions

During acquisition, raw data from Localizer and NFB sessions are stored in:

`offline-scripts-main/data/Raw/`

TSI-processed outputs are stored in:

`offline-scripts-main/data/online_processed_TSI_data/`

including HbO and HbR signals for short- and long-separation channels.

---

### Entry-point offline scripts

- `TSI_Data_Analysis_loc.m`  
- `TSI_Data_Analysis_NFB.m`  

These scripts:
- process TSI time series
- run GLM analysis (NIRS Brain AnalyzIR Toolbox)
- export beta values

---

## Recommended project structure

```text
PMI_Project/
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
```

---

## 2. Software Dependencies

The workflow was implemented on two separate laptops.

### Laptop A (acquisition + offline analysis)

- Aurora 2023.9 (NIRSport 2)
- MATLAB R2021b
- NIRS Brain AnalyzIR Toolbox
- QT-NIRS Toolbox (optional)
- Windows 10

Used for:
- fNIRS acquisition
- neurofeedback preparation
- offline analysis

---

### Laptop B (real-time experiment)

- Turbo-Satori 2.0 (TSI; Lührs & Goebel, 2017)
- Psychtoolbox-3 (Pelli, 1997)
- MATLAB R2018a
- Windows 10

Used for:
- localizer task
- neurofeedback task
- real-time signal processing

---

## 3. Data Acquisition Workflow

fNIRS data were recorded using NIRSport 2 with Aurora software.

### System setup
- NIRSport 2 controlled via Laptop A
- Ethernet connection between laptops for real-time streaming

---

### Experimental stages

#### Localizer
- Script: `PMI_EXP_01_LOCALIZER.m`
- Raw data: `data/Raw/`
- TSI output: `data/online_processed_TSI_data/`

---

#### Neurofeedback preparation
- Script: `PMI_EXP_02_NFB_PREPARATION.m`
- Computes:
  - subject-specific thresholds
  - 3 optimal neurofeedback channels

---

#### Neurofeedback training
- Script: `PMI_EXP_03_NFB.m`
- Uses precomputed thresholds and channels
- Records HbO/HbR signals, thresholds, and feedback state

---

## 4. Offline Analysis

Two MATLAB pipelines:

- `TSI_Data_Analysis_loc.m`
- `TSI_Data_Analysis_NFB.m`

### Processing steps
- HbO/HbR conversion
- Maintain of rest-task related periods
- GLM modeling (NIRS Brain AnalyzIR Toolbox)

### Intermediate outputs
- `preprocessing_PMI_localizer_offline.mat`
- `preprocessing_PMI_NFB_offline.mat`

### Final GLM output
- `GLM_PMI_offline.mat`

Stored in:
`offline-scripts-main/post-processed_tsi_data/`

---

## 5. GLM Beta Extraction and Visualization

### Beta extraction
Script:
- `extract_betas.m`

Outputs:
- `hbo_betas_average_NFB_channs.xlsx`
- `hbr_betas_average_NFB_channs.xlsx`

Stored in:
`offline-scripts-main/paper_figures_data/`

---

### Figure generation scripts

- `plot_betas_and_controlability_measures_fig3a_b.m`
- `cor_loc_nfb_fig4.m`
- `plot_percentage_of_ratios_fig3c.m`
- `table_ratios_run_level_NFBchans.m`

---

### Additional analyses

- CERQ / ERQ / DERS descriptive statistics  
- `pre_post_coordinates_stormnet.m` (STORM-Net cap displacement analysis)  
- `ratios_6seconds_after_task_participant_run_level.m`  

---


## 7. Data Availability



## 8. Citation

If you use this repository, please cite:

**Targeting emotion regulation with fNIRS neurofeedback training – feasibility study in healthy participants**
