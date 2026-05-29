%% ========================================================================
%  Extract GLM betas from individualized NFB channels (Localizer & NFB)
% ========================================================================
%
% MATLAB version: R2021b
%
% Description:
% This script extracts HbR GLM betas from individualized NFB channels
% for both Localizer and Neurofeedback (NFB) sessions. For each participant,
% the script selects the best channels, averages beta values across runs,
% and organizes the results into a structured table.
%
% Output:
% - A table where:
%   Column 1: Participant ID
%   Remaining columns: Mean beta values from the 3 best channels
%   across sessions and runs (per Condition).
%
% Notes:
% - Localizer and NFB outputs should be concatenated manually for
%   downstream statistical analysis.
% - HbR extraction is enabled by default.
% - HbO extraction code is available but commented out.
%
% % Created by Marianna Georgiou
% Department of Psychiatry, Psychotherapy and Psychosomatics, University 
% Hospital RWTH Aachen, Aachen, Germany
% email: mariannag43@gmail.com
%% ========================================================================



clear all; close all; clc;

%Adjust these two parameters as needed
mod = 'Localizer'; % 'Localizer' or 'NFB'
sessions = 4; % 3 for NFB, 4 for Localizer (4th = post-training localizer)

%% ========================================================================
%% 1. Setup paths and parameters
%% ========================================================================

% NOTE: adapt paths to local environment
RT_PATH = '\offline-scripts-main\data\online_processed_TSI_data\NFB\S';
MAINPATH = '\offline-scripts-main\post-processed_tsi_data\data\preprocessed\';

resultsMap = containers.Map();

%% ========================================================================
%% 2. Extract best channels per participant
%% ========================================================================

for s = 1:sessions

    RT_PATH = [RT_PATH num2str(s)];

    cd(RT_PATH)

    participants = dir('P*');   % participant folders (P01, P02, ...)
    participants = participants([participants.isdir]);

    bestChanDict = containers.Map();

    for p = 1:length(participants)

        pname = participants(p).name;
        ppath = fullfile(RT_PATH, pname);

        cd(ppath)
        load(dir('rt*').name);

        % best channels defined during NFB training
        best_chans = NFB_settings_online.channels;
        bestChanDict(pname) = best_chans;

    end

    %% ====================================================================
    %% 3. Load GLM data
    %% ====================================================================

    BETAS_PATH = [MAINPATH mod '\S' num2str(s)];
    cd(BETAS_PATH)

    if mod == "Localizer"
        load("PMI_Localizer_GLM.mat")
        runs_per_participant = 2;
    else
        load("PMI_NFB_GLM.mat")
        runs_per_participant = 3;
    end

    %% ====================================================================
    %% 4. Extract betas (HbR, selected condition)
    %% ====================================================================

    COND = 'PMI:01';

    % HbR index for selected condition
    idx_hbr = find(strcmp(SubjStats_pruned(1,1).variables.type, 'hbr') & ...
                   strcmp(SubjStats_pruned(1,1).variables.cond, COND));

    % IMPORTANT:
    % assumes SubjStats_pruned is ordered by participant in blocks of
    % size runs_per_participant

    for p = 1:23

        start_idx = (p-1)*runs_per_participant + 1;
        end_idx   = start_idx + runs_per_participant - 1;

        selected_runs = SubjStats_pruned(start_idx:end_idx);
        desc = selected_runs(1,1).description;

        % extract participant ID (e.g., P01, P12)
        match = regexp(desc, 'P\d{1,2}', 'match');
        participant_name = match{1};

        % reset per participant
        betas_hbr_loc = [];

        for n = 1:length(selected_runs)

            % extract HbR betas per run
            betas_hbr_loc(:, n) = selected_runs(1,n).beta(idx_hbr);

        end

        % select best channels
        best_runbetas = betas_hbr_loc(bestChanDict(participant_name), :);

        % average across selected channels
        avg_betas = mean(best_runbetas, 1);

        %% ================================================================
        %% 5. Aggregate results
        %% ================================================================

        if ~isKey(resultsMap, participant_name)
            entry.Participant = participant_name;
        else
            entry = resultsMap(participant_name);
        end

        % store session/run averages
        for r = 1:runs_per_participant
            colname = sprintf('%s_S%d_R%d', mod, s, r);
            entry.(colname) = avg_betas(r);
        end

        resultsMap(participant_name) = entry;

    end
end

%% ========================================================================
%% 6. Save output
%% ========================================================================

keysList = keys(resultsMap);
results = cellfun(@(k) resultsMap(k), keysList, 'UniformOutput', false);
results = [results{:}];

T = struct2table(results);

outfile = fullfile('\offline-scripts-main\paper_figures_data', ...
                   ['hbr_averthree_betas_1-4' mod '.xlsx']);

writetable(T, outfile);

disp(['Saved: ' outfile]);
