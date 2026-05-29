function [Hb_SDCcor, ScansQuality] = preprocessing_PMI_localizer_offline(raw, qtflag, NFB_Loc)


% %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% % ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Trim Baseline ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% job = nirs.modules.TrimBaseline;   %no need for trimming, we keep later only
% stimuli 1,2 %Marianna, 18.10.2024
% job.preBaseline = 30;
% job.postBaseline = 30;
% raw_trimmed = job.run(raw); 

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~ Signal Quality Assessment via QT-NIRS ~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% the signal quality assessment step is performed by using the qt-nirs
% toolbox. This toolbox must be downloaded, added to the MATLAB-path and
% some files need to be copied to the respective filders in the
% nirs-toolbox (cf. https://github.com/lpollonini/qt-nirs/wiki); Quality
% assessment is based on the scalp-coupling index (sciThreshold; 
% default = 0.75) and the peak spectral power (job.pspThreshold; 
% emppirical default = 0.1 should not be changed) (cf. Pollonini et al., 
% 2014, 2016). Moreover, with job.qThreshold (default = 0.75) a general
% minimal quality criteron can be defined. job.fCut = [0.5 2.5] are
% the default cut-off frequencies for separating the heartbeat from the
% signal. Note that regarding the Shannon-Nyquist theorem the samplin rate
% should be higher than twice the higher frequency of interest (i.e., 2*2.5
% Hz = 5 Hz), if the sampling frequency is lower, the cut-off should be
% reduced accordingly

% decide whether QT-NIRS to be used for channel QA 
if qtflag %added qtnirs flag %Marianna 18.10.2024
    qt_thresholds = [0.6 0.6 0.1]; % original quality thresholds
elseif ~qtflag
    qt_thresholds = [eps eps eps]; % "virtually" zero thresholds - removes no channel
end

job = nirs.modules.QT;
% possible Options and their default values
job.fCut = [0.5 2];                  % 1x2 array [fmin fmax] representing the bandpass 
                                     % of the cardiac pulsation
% job.windowSec = 5;                 % length in seconds of the window to partition 
                                     % the signal with 
% job.windowOverlap = 0;             % fraction overlap (0..0.99) between adjacent windows
job.qThreshold = qt_thresholds(1);   % required quality value (normalized; 0-1) of 
                                     % good-quality windows in every channel
% job.lambda_mask = 'all';           % binary array mapping the selected two wavelengths 
                                     % to compute the SCI
% job.dodFlag = 0;                   % flag indicating to work from DOD data
% job.guiFlag = 0;                   % flag indicating whether to start or not the 
                                     % qt-nirs GUI
% job.condMask = 'resting';          % binary mask (or the keyword 'all') to indicate 
                                     % the conditions for computing the periods of interest
job.sciThreshold = qt_thresholds(2); % threshold for scalp coupling index (e.g., good
                                     % quality if SCI >= threshold)
job.pspThreshold = qt_thresholds(3); % PSP threshold, empirically set at 0.1
ScansQuality = job.run(raw);

% Draw Signal Quality Assessment
% ScansQuality.drawGroup('sci'); % scalp coupling index (sci)
% ScansQuality.drawGroup('psp'); % peak spectral power (psp)
% ScansQuality.drawGroup('sq');  % signal quality (sci & psp)
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %


%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                             PREPROCESSING                               %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~ Conversion to optical density changes (dOD) ~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% this function converts the raw light intensity to changes optical density 
% in optical density: dOD = -log(raw/mean(raw)); Log is the natural
% logarithm

job = nirs.modules.OpticalDensity;
dOD = job.run(raw); 
% % % % % % % % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% % % % % % % 
% % % % % % % 
% % % % % % % %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% % % % % % % % ~~~~~~~~~~~~~~~~~~~~~~ Motion Correction ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% % % % % % % % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% % % % % % % % Here, we apply a motion artifact (MA) correction step based on the dOD data by
% % % % % % % % using tha TDDR algorithm (Fishburn et al., 2019) implemented in this toolbox 
% % % % % % % % There are not more options implemented in this toolbox for MA correction;
% % % % % % % % it is also possible to skip this step if you are planning to use the
% % % % % % % % AR-ILS GLM für your analysis because it was alo shown to handle MA (cf.
% % % % % % % % Barker et al., 2013)
% % % % % % % 
% % % % % % % job = nirs.modules.TDDR;
% % % % % % % % possible Options and their default values
% % % % % % % % job.usePCA = false;         % Do correction on the PrinComp of the data 
% % % % % % %                               % instead of channel space
% % % % % % % dOD_MC = job.run(dOD); 
% % % % % % % % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% % % % % % % 
% % % % % % % 
% % % % % % % %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% % % % % % % % ~~~~~~~~ Conversion to Hemoglobin Concentration Changes (dHbX) ~~~~~~~~ %
% % % % % % % % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% % % % % % % 
% % % % % % % % this function performs the conversion from optical density changes to
% % % % % % % % hemoglobin concentration changes by using the modified Beer Lambert law.
% % % % % % % % Instead of using the differential pathlength factor (DPF) the default in
% % % % % % % % this function is using the partial pathlength factor (PPF) which is the
% % % % % % % % DPF corrected by a value called differential volume factor (PVF; cf.
% % % % % % % % Whitemann et al., 2018). You can change to DPFs by simply adding them to
% job.PPF = [DPF_wavelength1, DPF_wavelength2];

job = nirs.modules.BeerLambertLaw; % using default of PPF = 0.1
% possible Options and their default values
% job.PPF = 5 / 50;   % partial pathlength factor 
job.PPF = [6.4, 5.75]; %recommended from TSI paper and Franzi
dHbX = job.run(dOD);
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~ Divide Data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%Added runs division %Marianna 09.01.2025
% Get experimnent mid point in time
if isempty(dHbX(1).stimulus('stim_channel5'))
    no_break = 0;
else
    no_break = dHbX(1).stimulus('stim_channel5').count;
end
no_runs=no_break+1; % number of runs
no_trials=dHbX(1).stimulus('stim_channel2').count/no_runs; % number of trials in a run

% Discard stims 0,5,7
dHbx_div = dHbX;
job = nirs.modules.DiscardStims;
job.listOfStims = {'stim_channel0', 'stim_channel5', 'stim_channel7','stim_aux1','stim_aux2'};
dHbx_div = job.run(dHbx_div);

dHbX_run=[];

for sub = 1:length(dHbx_div)

    %Save stimuli to excel file
    nirs.design.save_stim2excel(dHbx_div(sub),'stimu.xlsx');

    %Split the runs
    [split_data]=split_runs_localizer_offline('stimu.xlsx', no_trials, no_runs, dHbx_div(sub), NFB_Loc(sub));

    dHbX_run=[dHbX_run ; split_data];
    dumquality(1,((sub-1)*no_runs+1):(sub*no_runs)) = ScansQuality(sub); % Size of the scan quality must match the number of datasets

end

ScansQuality = dumquality;
Hb_SDCcor = dHbX_run;
clear dumquality

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~ Normalize Data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% % % % % % Hb_normalized = dHbX_run;
% % % % % % 
% % % % % % % normalize data
% % % % % % for subj = 1:size(Hb_normalized, 1)
% % % % % %     Hb_normalized(subj).data = normalize(Hb_normalized(subj).data);
% % % % % % end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %



%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Add SDC Info ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% here the toolbox adds the information about the short distance channels
% (SDCs) to the data. This step results in an additional column in the
% raw.probe.link structure -> raw.probe.link.ShortSeparation, containing
% a 1 if the channel is a SDC and a 0 if it is a regular-distance channel
% Note: the default value for this process is 15 mm (check raw.probe.distances
% for the distances stored in your data set)
% Note: this step could be done at any other time

job = nirs.modules.LabelShortSeperation;
job.max_distance = 10; % define maximally allowed SDC distance in mm
Hb_SDCcor = job.run(Hb_SDCcor);

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %


%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~ Systemic Activity Correction with GLM ~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% to clean the data a GLM will be run, including only SDC as regressors. To
% avoid removing any task-related activity, task-related information (i.e.,
% stimulus info) has to be removed
% % % % % % 
% % % % % % res = Hb_normalized;
% % % % % % job = nirs.modules.DiscardStims;
% % % % % % % job.listOfStims = {'0', '1', '2', '5', '7'};
% % % % % % job.listOfStims = {'stim_channel0', 'stim_channel1', 'stim_channel2', 'stim_channel5', 'stim_channel7', 'stim_aux1', 'stim_aux2', 'stim_aux3', 'stim_aux4'};
% % % % % % res = job.run(res);
% % % % % % 
% % % % % % % Add SDCs as regressors
% % % % % % job = nirs.modules.AddShortSeperationRegressors;
% % % % % % job.scICA = true; %it is commented out in AddShortSeperationRegressors 
% % % % % % job.allChans = true; %it is commented out in AddShortSeperationRegressors
% % % % % % res = job.run(res);
% % % % % % 
% % % % % % % run cleaning GLM
% % % % % % job = nirs.modules.AR_IRLS;
% % % % % % job.trend_func = @(t) nirs.design.trend.constant(t); % add constant for trend
% % % % % % 
% % % % % % % get residuals as cleaned data
% % % % % % job_resid = advanced.nirs.modules.GLMResiduals;
% % % % % % job_resid.GLMjob = job;
% % % % % % 
% % % % % % hb_residuals = job_resid.run(res);
% % % % % % 
% % % % % % Hb_SDCcor_unfiltered = Hb_normalized;
% % % % % % for s = 1:size(res, 1)
% % % % % %     Hb_SDCcor_unfiltered(s).data = hb_residuals(s).data; % replace with cleaned data
% % % % % % end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Filtering ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% we changed order to: GLM SDC correction, then filtering
% in order to have same order as in real-time TSI processing

% If you want to apply a temporal filter to remove physiological confounds
% (e.g., cardiac oscillations (~1 Hz), respiration (~0.3 Hz), Mayer waves 
% (~0.1 Hz) etc.) you can choose between IIR and FIR filters, otherwise you 
% can simply skipt this preprocessing step. Note: make sure that do not
% filter-out your task-frequency 
% (i.e., 1/(task_duration + rest_duration [s]))
% These are MATLAB built-in functions and thus have to be applied on the 
% data directly as there is no filter module in this toolbox. 
% % % % 
% % % % Hb_SDCcor = Hb_SDCcor_unfiltered; % infinite impulse response filer (IIR)
% % % % 
% % % % hpf = 0.02;   % high pass filter cutoff frequency 
% % % %               % could not use Pinti's recommendation (0.015) due to artifacts
% % % % lpf = 0.09;   % low pass filter cutoff frequency 
% % % %               % (as recommended by Pinti et al., 2019)
% % % % sf = dHbX.Fs; % sampling frequency
% % % % 
% % % % % IIR Butterworth filter
% % % % order = 4; % filter orders are low for IIR filters, otherwise they get 
% % % %            % instable (cf. Pinti et al., 2019)
% % % % [b, a] = butter(order, lpf*2/sf);
% % % % [d, c] = butter(order, hpf*2/sf, 'high');
% % % % 
% % % % for s = 1:size(Hb_SDCcor, 1)
% % % %     lpf_dat = [];
% % % %     hpf_data = [];
% % % % 
% % % %     lpf_dat = filtfilt(b, a, Hb_SDCcor(s).data); % zero-phase/acausal
% % % %                                                        % filter
% % % %     hpf_data = filtfilt(d, c, lpf_dat); % instead, one could also use the 
% % % %                                         % bp filter directly 
% % % % 
% % % %     Hb_SDCcor(s).data = hpf_data;
% % % % end 
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

end