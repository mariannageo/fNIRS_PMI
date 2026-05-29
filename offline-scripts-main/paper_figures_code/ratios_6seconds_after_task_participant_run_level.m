%% ========================================================================
%% Initialize container for all extracted ratio observations
%% ========================================================================
all_rows = []; % will store trial/second-level ratio values as table rows

%% ========================================================================
%% Loop over sessions (S1–S3)
%% ========================================================================
for session = 1:3

    sessionStr = ['S' num2str(session)];

    % ---------------------------------------------------------------------
    % Define file paths (adjust to local environment)
    % ---------------------------------------------------------------------
    MAINPATH = ['\offline-scripts-main\data\'];
    rt_PATH = [MAINPATH 'online_processed_TSI_data\NFB\S' num2str(session)];
    NFB_tsi_path = ['\offline-scripts-main\post-processed_tsi_data\data\preprocessed\NFB\S' num2str(session)];

    %% ====================================================================
    %% Load preprocessed TSI data (HbR SDC-corrected signals)
    %% ====================================================================
    processed_tsi = dir(fullfile(NFB_tsi_path, 'PMI_NFB_preprocessed.mat'));
    NFB_tsi_b = load(processed_tsi.name);

    % Extract HbR signal structure (spatially-dispersion corrected)
    Hb_SDCcor = NFB_tsi_b.Hb_SDCcor;

    %% ====================================================================
    %% Loop over participants
    %% ====================================================================
    participants = dir(fullfile(rt_PATH,'P*'));
    participants = participants(~contains({participants.name},'P28'));

    for i = 1:length(participants)

        fprintf('Participant %.2f\n', i);

        participantPath = fullfile(rt_PATH, participants(i).name);

        % -----------------------------------------------------------------
        % Load real-time NFB settings and trial structure
        % -----------------------------------------------------------------
        rtFiles = dir(fullfile(participantPath,'rt*'));
        fileToLoad = fullfile(participantPath, rtFiles(1).name);
        rt = load(fileToLoad);

        threshold = rt.NFB_settings_online.threshold;   % NFB threshold
        NFB_chans = rt.NFB_settings_online.channels;     % selected channels
        fs = rt.NFB_settings_online.sf;                  % sampling frequency

        %% ================================================================
        %% Match corresponding TSI runs for current session + participant
        %% ================================================================
        mask = arrayfun(@(x) ...
            any(strcmp(sessionStr, split(x.description, filesep))) && ...
            any(strcmp(participants(i).name, split(x.description, filesep))), ...
            Hb_SDCcor);

        tsi_data_simu2 = Hb_SDCcor(mask);

        %% ================================================================
        %% Loop over TSI runs
        %% ================================================================
        for tsi_pos = 1:size(tsi_data_simu2,1)

            fprintf('Run %.2f\n', tsi_pos);

            tsi_run = tsi_data_simu2(tsi_pos,1);
            dat = tsi_run.data;

            % -----------------------------------------------------------------
            % Extract HbR channels and select NFB channels
            % -----------------------------------------------------------------
            dat_hbr = dat(:,2:2:end);
            dat_hbr_best_nfb = dat_hbr(:, NFB_chans(1:3));

            if isempty(dat_hbr_best_nfb)
                fprintf('3 best chans NFB data empty. Skipping...\n');
                continue;
            end

            % -----------------------------------------------------------------
            % Extract task and rest trigger indices
            % -----------------------------------------------------------------
            [~, rest_triggers] = ismember(tsi_run.stimulus('stim_channel1').onset, tsi_run.time);
            [~, task_triggers] = ismember(tsi_run.stimulus('stim_channel2').onset, tsi_run.time);

            bl_window   = round(3 * fs);   % baseline window (3 s)
            rest_window = round(10 * fs);  % rest window (10 s)

            ratios_run = {};

            %% ============================================================
            %% Loop over task trials
            %% ============================================================
            for t = 1:length(task_triggers)

                % ---------------------------------------------------------
                % Baseline correction (pre-task 3 s median)
                % ---------------------------------------------------------
                mean_bl = nanmedian( ...
                    dat_hbr_best_nfb(task_triggers(t)-bl_window:task_triggers(t)-1, :), 1);

                % ---------------------------------------------------------
                % Extract task segment (task → next rest trigger)
                % ---------------------------------------------------------
                bl_corr_task = dat_hbr_best_nfb( ...
                    task_triggers(t)-rest_window : rest_triggers(t+1), :) - mean_bl;

                % ---------------------------------------------------------
                % Temporal smoothing (moving median ~2 s window)
                % ---------------------------------------------------------
                median_moving_window_vio = movmedian( ...
                    bl_corr_task, round(2*fs)-1, "omitnan", 'Endpoints', 'fill');

                [T, C] = size(median_moving_window_vio);
                n_seconds = round(T / fs);

                %% ====================================================
                %% Compute per-second ratios (signal / threshold)
                %% ====================================================
                for s = 1:n_seconds

                    idx_start = round((s-1)*fs) + 1;
                    idx_end   = round(s*fs);

                    if idx_end > T
                        continue
                    end

                    second_ratios = [];

                    % -------------------------------------------------
                    % Compute ratio per channel and timepoint
                    % -------------------------------------------------
                    for ch = 1:C

                        segment = median_moving_window_vio(idx_start:idx_end, ch);
                        ratios = segment / threshold;

                        second_ratios = [second_ratios; ratios];

                    end

                    % Store [trial × second] cell array
                    ratios_run{t,s} = second_ratios;

                end
            end

            %% ============================================================
            %% Convert cell array into long-format table
            %% ============================================================
            for tr = 1:size(ratios_run,1)
                for s = 1:size(ratios_run,2)

                    data = ratios_run{tr,s};

                    if isempty(data)
                        continue
                    end

                    n = length(data);

                    rows = table( ...
                        repmat(session,n,1), ...
                        repmat({participants(i).name},n,1), ...
                        repmat(tsi_pos,n,1), ...
                        repmat(tr,n,1), ...
                        repmat(s,n,1), ...
                        data, ...
                        'VariableNames', ...
                        {'session','participant','run','trial','second','ratio'});

                    all_rows = [all_rows ; rows];

                end
            end

        end
    end
end

%% ========================================================================
%% Final ratio table construction
%% ========================================================================
ratio_table = all_rows;

% Keep only data from 6th second onward (hemodynamic delay correction)
ratio_table = ratio_table(ratio_table.second >= 6 , :);

head(ratio_table)

%% ========================================================================
%% Binary threshold indicators
%% ========================================================================
ratio_table.reach60  = ratio_table.ratio >= 0.6;
ratio_table.reach100 = ratio_table.ratio >= 1;

%% ========================================================================
%% Aggregate: trial-level summary
%% ========================================================================
block_table = groupsummary( ...
    ratio_table, ...
    {'session','participant','run','trial'}, ...
    'mean', ...
    {'reach60','reach100'});

block_table.percent60  = block_table.mean_reach60  * 100;
block_table.percent100 = block_table.mean_reach100 * 100;

%% ========================================================================
%% Aggregate: run-level summary
%% ========================================================================
run_table = groupsummary( ...
    block_table, ...
    {'session','participant','run'}, ...
    'mean', ...
    {'percent60','percent100'});

run_table = sortrows(run_table, {'participant','run'});

%% ========================================================================
%% Reshape to wide format (participant × runs)
%% ========================================================================
participants = unique(run_table.participant);

numP = length(participants);
numRuns = max(run_table.run);

wide_table = table(participants, 'VariableNames', {'participant'});

for r = 1:numRuns

    col60  = run_table.mean_percent60(run_table.run == r);
    col100 = run_table.mean_percent100(run_table.run == r);

    wide_table.(['S1_Run' num2str(r) '_percent60'])  = col60;
    wide_table.(['S1_Run' num2str(r) '_percent100']) = col100;

end

%% ========================================================================
%% Save output table
%% ========================================================================
disp(wide_table)

filename = ['after6ratios_S' num2str(session) '.xlsx'];
writetable(wide_table, filename);