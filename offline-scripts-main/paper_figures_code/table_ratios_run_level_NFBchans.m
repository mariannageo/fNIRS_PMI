%% ==================================================================================================================
%% Real-time signal-to-threshold ratio extraction during Neurofeedback (NFB)
%% ==================================================================================================================
%
% Description:
% This script reconstructs the online neurofeedback (NFB) signal processing
% pipeline using post-processed TSI data. It computes time-resolved
% signal-to-threshold ratios for each participant, session, run, and trial.
%
% The pipeline replicates the real-time NFB computation by applying:
% - selection of individualized NFB channels,
% - extraction of HbR signals,
% - baseline correction using a pre-task window,
% - temporal smoothing using a moving median filter (~2 s window),
% - normalization by participant-specific thresholds.
%
% Output:
% - Long-format table containing:
%   session, participant ID, run, trial, and ratio time series
%
% Data sources:
% - Post-processed TSI data (Hb_SDCcor structure)
% - Real-time NFB configuration (channels, sampling frequency, thresholds)
%
% Notes:
% - Only HbR signals are used
% - Top 3 individualized NFB channels are included per participant
% - Designed to replicate online NFB processing offline for analysis
%
% Created by Marianna Georgiou
% Department of Psychiatry, Psychotherapy and Psychosomatics
% University Hospital RWTH Aachen, Germany
% email: mariannag43@gmail.com
%
%% ==================================================================================================================
%% 1. Initialization and session loop
%% ==================================================================================================================

all_rows = []; % container for aggregated output table

for session = 1:3

    sessionStr = ['S' num2str(session)];

    % NOTE: adapt paths to local environment
    MAINPATH = ['\offline-scripts-main\data\'];
    NFB_tsi_path = ['\offline-scripts-main\post-processed_tsi_data\data\preprocessed\NFB\S' num2str(session)];
    rt_PATH = [MAINPATH 'online_processed_TSI_data\NFB\S' num2str(session)];

    %% ====================================================================
    %% 2. Load preprocessed TSI data
    %% ====================================================================

    processed_tsi = dir(fullfile(NFB_tsi_path, 'PMI_NFB_preprocessed.mat'));
    NFB_tsi_b = load(processed_tsi.name);

    % Extract HbR SDC-corrected data structure
    Hb_SDCcor = NFB_tsi_b.Hb_SDCcor;

    %% ====================================================================
    %% 3. Identify participants
    %% ====================================================================

    participants = dir(fullfile(rt_PATH,'P*'));

    % Exclude participant with known data quality issues
    participants = participants(~contains({participants.name},'P28'));

    %% ====================================================================
    %% 4. Loop over participants
    %% ====================================================================

    for i = 1:length(participants)

        participants(i).name
        fprintf('Participant %.2f\n', i);

        participantPath = fullfile(rt_PATH, participants(i).name);

        rtFiles = dir(fullfile(participantPath,'rt*'));
        fileToLoad = fullfile(participantPath, rtFiles(1).name);
        rt = load(fileToLoad);

        %% ------------------------------------------------------------
        %% 4.1 Extract NFB configuration
        %% ------------------------------------------------------------

        threshold = rt.NFB_settings_online.threshold;

        % Skip invalid threshold definitions
        if threshold > 0
            disp('Threshold is positive');
            continue;
        end

        NFB_chans = rt.NFB_settings_online.channels;
        fs = rt.NFB_settings_online.sf;

        %% ------------------------------------------------------------
        %% 4.2 Match TSI runs to session and participant
        %% ------------------------------------------------------------

        mask = arrayfun(@(x) ...
            any(strcmp(sessionStr, split(x.description, filesep))) && ...
            any(strcmp(participants(i).name, split(x.description, filesep))), ...
            Hb_SDCcor);

        tsi_data_simu2 = Hb_SDCcor(mask);

        %% =================================================================
        %% 5. Loop over runs (TSI segments)
        %% =================================================================

        for tsi_pos = 1:size(tsi_data_simu2,1)

            fprintf('Run %.2f\n', tsi_pos);

            tsi_run = tsi_data_simu2(tsi_pos,1);

            dat = tsi_run.data;

            % Extract HbR channels and select top 3 NFB channels
            dat_hbr = dat(:,2:2:end);
            dat_hbr_best_nfb = dat_hbr(:, NFB_chans(1:3));

            if isempty(dat_hbr_best_nfb)
                fprintf('3 best chans NFB data empty. Skipping...\n');
                continue;
            end

            %% ------------------------------------------------------------
            %% 5.1 Extract task and rest triggers
            %% ------------------------------------------------------------

            [~, rest_triggers] = ismember(tsi_run.stimulus('stim_channel1').onset, tsi_run.time);
            [~, task_triggers] = ismember(tsi_run.stimulus('stim_channel2').onset, tsi_run.time);

            bl_window = round(3 * fs);
            rest_window = round(10 * fs);

            ratios_run = {};

            %% ------------------------------------------------------------
            %% 5.2 Trial-wise signal processing
            %% ------------------------------------------------------------

            for t = 1:length(task_triggers)

                trial = t;

                % Baseline estimation (pre-task window)
                mean_bl = nanmedian(dat_hbr_best_nfb(task_triggers(t)-bl_window:task_triggers(t)-1,:),1);

                % Baseline correction for task segment
                bl_corr_task = dat_hbr_best_nfb(task_triggers(t)-rest_window:rest_triggers(t+1),:) - mean_bl;

                % Temporal smoothing (replicates online filtering)
                moving_window_vio = bl_corr_task;
                median_moving_window_vio = movmedian(moving_window_vio, round(2*fs)-1, ...
                    "omitnan",'Endpoints','fill');

                plot(median_moving_window_vio)

                %% --------------------------------------------------------
                %% 5.3 Normalize by threshold (signal-to-threshold ratio)
                %% --------------------------------------------------------

                second_ratios = [];
                [T,C] = size(median_moving_window_vio);

                for ch = 1:C

                    segment = median_moving_window_vio(:,ch);
                    ratios = segment / threshold;

                    second_ratios = [second_ratios, ratios];

                end

                % Average across selected channels
                ratios_run{t} = mean(second_ratios,2);

            end

            %% =================================================================
            %% 6. Store results in long-format table
            %% =================================================================

            for tr = 1:size(ratios_run,2)

                data = ratios_run{tr};

                if isempty(data)
                    continue
                end

                n = length(data);

                rows = table( ...
                    repmat(session,n,1), ...
                    repmat({participants(i).name},n,1), ...
                    repmat(tsi_pos,n,1), ...
                    repmat(tr,n,1), ...
                    data, ...
                    'VariableNames',{'session','participant','run','trial','ratio'});

                all_rows = [all_rows ; rows];

            end
        end
    end
end

%% ==================================================================================================================
%% 7. Save output table
%% ==================================================================================================================

ratio_table = all_rows;
head(ratio_table)

save(['table_ratios_S' num2str(session) '.mat'], 'ratio_table')