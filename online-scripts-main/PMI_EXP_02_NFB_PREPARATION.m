%% PREPARATION SCRIPT FOR POSITIVE MENTAL IMAGERY EXPERIMENT
% change log

clear all; close all; clc;
%% NFB PREPARATION SCRIPT: find best channel and generate thresholds for NFB using online TSI data
% Created by Franziska Klein a,b,c edited by Marianna Georgiou a, Murat C.
% Mutlu a
% and David Mehler a,b,d
% a Department of Psychiatry, Psychotherapy and Psychosomatics, University Hospital RWTH Aachen, Aachen, Germany
% b Biomedical Devices and Systems Group, R&D Division Health, OFFIS - Institute for Information Technology, Oldenburg, Germany
% c Assistive Systems and Medical Device Technology Group, Department of Health Services Research, University of Oldenburg, Oldenburg, Germany
% d School of Psychology, Cardiff University Brain Research Imaging Center (CUBRIC), Cardiff University, Cardiff, UK

% Using Matlab 2021b

%%%%%%% SET THE FOLLOWING PATHS %%%%%%%%%%%%%%%%%%%%%%%%%%%
rt_PATH = ''; %'Project\online-scripts-main\rt\PMI\'; 
PATHOUT = ''; %'Project\online-scripts-main\rt\PMI\';
RAW_DATA = ''; %'C:\Users\User\Documents\NIRx\Data'

% enter subject and session number - make sure order is the same across scripts to avoide user mistakes!
subject = input('Enter subject number: ');
session = input('Enter session number: ');

% path naming changes with date and run, to keep flexibel, select manually!
% recording with original run folder name is used
% Option 1: 'C:\Users\User\Documents\NIRx\Data\PMI\Localizer\'
%AURORA_PATH = uigetdir('C:\Users\mgeorgiou\OneDrive - Uniklinik RWTH Aachen\Dokumente\fNIRS_feasibility\Code\offline_analysis\fnirs-offline-analysis\data_new\raw\localizer\S1');
AURORA_PATH = uigetdir(RAW_DATA); 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %



%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ load Data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% load .nirs file (subject folder needs renaming before, e.g., AURORA folder
% for subject 1 session 3 should be PMI_LOCALIZER_s1_ses3)

%% DAVID: build recording file name from path of session of interest
all_files      = dir(AURORA_PATH);
recording_name = all_files(3).name;
if subject < 10
    % load offline (AURORA) recorded data
    raw = nirs.io.loadDotNirs([AURORA_PATH, '\', recording_name], 1);
    %%%raw = nirs.io.loadDotNirs(AURORA_PATH);
    
    
    % load online collected data from localizer run
    load([rt_PATH, 'PMI_NFB_LOCALIZER_s0', num2str(subject), '_session_', num2str(session), '.mat']);
    
else
    % load offline (AURORA) recorded data
    raw = nirs.io.loadDotNirs([AURORA_PATH, '\', recording_name], 1);
    
    % load online collected dtaa from localizer run
    load([rt_PATH, 'PMI_NFB_LOCALIZER_s', num2str(subject), '_session_', num2str(session), '.mat']);
end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %


%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                        PREPROCESSING & GLM
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% Preprocessing
qtflag=0; % or 1
% Get qtnirs results and split aurora data to be overwritten by tsi data
[Hb_SDCcor, ScansQuality] = preprocessing_PMI_localizer_online(raw, qtflag, NFB_Loc);

% replace aurora data with tsi preprocessed data
[tsi_data] = tsi2nirs_localizer_online(Hb_SDCcor, NFB_Loc);

%Make sure that tsi_data.time and .data have the same length, sometimes
%they differ by 1,2 timepoints
[dataRows, dataCols] = size(tsi_data);
if dataRows == 1 && dataCols == 1
    if length(tsi_data.data(:,1)) > length(tsi_data.time)
        tsi_data.data=tsi_data.data(1:length(tsi_data.time),:);
    end
elseif dataRows == 2 && dataCols == 1
    if length(tsi_data(1,1).data(:,1)) > length(tsi_data(1,1).time)
        tsi_data(1,1).data=tsi_data(1,1).data(1:length(tsi_data(1,1).time),:);
    end
    if length(tsi_data(2,1).data(:,1)) > length(tsi_data(2,1).time)
        tsi_data(2,1).data=tsi_data(2,1).data(1:length(tsi_data(2,1).time),:);
    end
end

% normalize data before GLM
for ii=1:length(tsi_data)
    dumdat = tsi_data(ii);
    dumdat.data = normalize(dumdat.data);
    tsi_data(ii).data = dumdat.data;
end   %by Marianna

%Apply GLM on TSI data
SubjStats_pruned_loc = GLM_PMI_localizer_online(tsi_data);


%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                           EXTRACT BETAS
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
COND = 'PMI:01'; % task, PMI:02 and PMI:03 are derivatives

% find indices of all HbR channels in variables table of glm output
idx_hbr = find(strcmp(SubjStats_pruned_loc(1,1).variables.type, 'hbr') & ...
    strcmp(SubjStats_pruned_loc(1,1).variables.cond, COND));

for n = 1:length(SubjStats_pruned_loc)
    % extract betas for localizer
    betas_hbr_loc(:, n) = SubjStats_pruned_loc(1,n).beta(idx_hbr);
end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %


%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                           CHANNEL SELECTION
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% CONSTANT! NEVER CHANGE!
% set number of best channels that shall be selected
%changed from 5 to 3 to match with the 3 polygons NFB representation
N_CHAN_SEL = 3;

% layout specifications
% all idcs describe the idcs that are used in nirs-toolbox, i.e. they are
% the indices you need to read out src-det pairs in the probe.link table

% without IFG, midline is included in left, indices related to WFU Pick
% Atlas
dlPFC_chans_left = [8 10 12 16 18 20 32]; % channel indices for HbR dlPFC left
% Respective HbO channels can be just selected with [2 4 6 10 12 30 54] -1;

% find left DLPFC channel indices in idx_hbr
[mask_dlPFC_left_hbr, mask_dlPFC_left_hbr_idx] = ismember(idx_hbr, dlPFC_chans_left); % HbR dlPFC left, mask for idx_hbr vector
idcs_dlPFC_left_hbr     = idx_hbr(mask_dlPFC_left_hbr); % HbR dlPFC left
% and corresponding indices for TSI
chans_dlPFC_left_hbr_TSI = find(mask_dlPFC_left_hbr_idx);

% mask the betas depending on layout
betas_hbr_loc_dlPFC_left = betas_hbr_loc(mask_dlPFC_left_hbr, :);

% sort each subjects' HbR in ascending order
[betas_hbr_loc_dlPFC_left_sorted, betas_hbr_loc_dlPFC_left_chan_idcs] = sort_beta_pairs_localizer_online(betas_hbr_loc_dlPFC_left);

% check if enough channels remain for NFB
betas_hbr_loc_dlPFC_left_chan_idcs(isnan(betas_hbr_loc_dlPFC_left_sorted)) = [] ;
if length(betas_hbr_loc_dlPFC_left_chan_idcs) < 3
    error('Not enough good quality channel. Please re-do the localizer. If there are not enough good quality channels after the second localizer run, the session cannot be continued.')
elseif length(betas_hbr_loc_dlPFC_left_chan_idcs) > N_CHAN_SEL
    betas_hbr_loc_dlPFC_left_chan_idcs = betas_hbr_loc_dlPFC_left_chan_idcs(1:N_CHAN_SEL);
end

% channels ordered for online NFB (TSI)
NFB_chans = chans_dlPFC_left_hbr_TSI(betas_hbr_loc_dlPFC_left_chan_idcs);
best_chan = NFB_chans(1);
% channels ordered for offline data (AURORA)
NFB_chans_offline = idcs_dlPFC_left_hbr(betas_hbr_loc_dlPFC_left_chan_idcs);
% best_chan = NFB_chans_offline(1); % offline different index than online,
% not needed because threshold calculation is based on online TSI data and
% hence other indices
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %


%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                         THRESHOLD COMPUTATION
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% extract trials from ONLINE TSI (LOCALIZER) data

% keeping the last 3 seconds of rest for BL computation (could be some
% task activity going on from previous task period)
bl_keep     = 3; % was "bl_skip = 6" before
sf          = raw.Fs;  % 10.17 for 8x8; % sampling rate
dp_BL_start = round(bl_keep*sf); % beginning wiht   second 6.

min_hbr  = [];
delay    = 6; % skip first six seconds for minimum calculation
dp_delay = round(delay*sf); % delay as time points
trial_minima_online = [];
% for r = 1:size(NFB_Loc.NFB_dat_oxy, 1) % for all runs - OLD session level analysis
%r=min_ind;
for r = 1:size(NFB_Loc.NFB_dat_deoxy, 1) % for all trials
    for t = 1:size(NFB_Loc.NFB_dat_deoxy, 2) % for all trials
        
        % extract task and rest data for current trial
        curr_trial_task_data      = NFB_Loc.NFB_dat_deoxy{r, t}(:, best_chan);
        curr_trial_rest_data_full = NFB_Loc.Rest_dat_deoxy{r, t}(:, best_chan);
        
        % find baseline onset and extract BL data
        curr_trial_rest_data_BL = curr_trial_rest_data_full((end-dp_BL_start):end); % changed to keep last 3 seconds of the rest period
        
        % average across BL data points and BL correct the task data
        BL_online         = nanmedian(curr_trial_rest_data_BL);
        curr_trial_online = curr_trial_task_data - BL_online; % BL corrected
        
        % find and extract minimum value after delay
        trial_minima_online = [trial_minima_online min(curr_trial_online(dp_delay+1:end))]; % determining minima after initial 6 seconds
    end
end
% end
% average across all minima
threshold_online = median(trial_minima_online);
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% save online data for NFB run
% NFB_settings_online.channels  = NFB_chans(:, min_ind);
NFB_settings_online.channels  = NFB_chans;

NFB_settings_online.threshold = threshold_online;
NFB_settings_online.sf = sf;
if subject < 10
    save([PATHOUT 'rt_PMI_NFB_chans', '_s0', num2str(subject), '_session', num2str(session), '_online.mat'], 'NFB_settings_online');
else
    save([PATHOUT 'rt_PMI_NFB_chans', '_s', num2str(subject), '_session', num2str(session), '_online.mat'], 'NFB_settings_online');
end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
