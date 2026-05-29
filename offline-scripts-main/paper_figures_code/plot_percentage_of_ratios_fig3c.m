%% ==================================================================================================================
%% Temporal evolution of signal-to-threshold ratios across sessions
%% ==================================================================================================================
%
% Description:
% This script visualizes the temporal evolution of signal-to-threshold ratios
% across three experimental sessions (S1–S3). For each session, the proportion
% of samples exceeding individualized thresholds is computed at two levels
% (0.6 and 1.0 of the threshold) and expressed as a percentage per second.
%
% The resulting time-resolved percentage curves reflect how often the measured
% signal exceeds predefined individualized thresholds over the course of a trial.
% This allows comparison of signal dynamics across sessions and evaluation of
% task-related modulation over time.
%Created by Marianna Georgiou
% Department of Psychiatry, Psychotherapy and Psychosomatics, University Hospital RWTH Aachen, Aachen, Germany
% email: mariannag43@gmail.com
%% ==================================================================================================================
clear; clc;

% NOTE: adapt paths to local environment
outPath = '\offline-scripts-main\paper_figures_data\plots';

%% --- Sampling frequency ---
fs = 10.1725; % Hz

%% --- Load data ---
data1 = load('\offline-scripts-main\paper_figures_data\table_ratios_S1.mat');
data2 = load('\offline-scripts-main\paper_figures_data\table_ratios_S2.mat');
data3 = load('\offline-scripts-main\paper_figures_data\table_ratios_S3.mat');

T1 = data1.ratio_table;
T2 = data2.ratio_table;
T3 = data3.ratio_table;

Tables = {T1, T2, T3};

%% --- Colors ---
session_colors = [0.894 0.102 0.110;
                  0.215 0.494 0.721;
                  0.302 0.686 0.290];

session_names = {'S1','S2','S3'};

figure('Units','inches','Position',[1 1 4.25 3],'Color','w');
hold on;

%% Store plot handles for legend
hPlot = gobjects(0);
legend_labels = {};

for s = 1:3
    
    T = Tables{s};
    
    T.timepoint = zeros(height(T),1);

    [G,~,idx] = unique(T(:,{'session','participant','run','trial'}),'rows');

    for g = 1:height(G)
        ind = (idx == g);
        tp = (1:sum(ind))';
        
        temp_idx = find(ind);
        T.timepoint(temp_idx) = tp;
    end

    %% --- Convert to seconds ---
    T.time_sec = T.timepoint / fs;
    T.second = floor(T.time_sec);

    %% --- Compute per-second percentages ---
    pct_06 = varfun(@(x) mean(x > 0.6)*100, T, ...
        'InputVariables','ratio', ...
        'GroupingVariables','second');

    pct_1 = varfun(@(x) mean(x > 1)*100, T, ...
        'InputVariables','ratio', ...
        'GroupingVariables','second');

    %% --- Plot 60% threshold ---
    h1 = plot(pct_06.second, pct_06.Fun_ratio, '-', ...
        'Color', session_colors(s,:), 'LineWidth', 1.5);

    %% --- Plot 100% threshold ---
    h2 = plot(pct_1.second, pct_1.Fun_ratio, '--', ...
        'Color', session_colors(s,:), 'LineWidth', 1.5);

    hPlot(end+1:end+2) = [h1 h2];
    legend_labels{end+1} = [session_names{s} ' 60%'];
    legend_labels{end+1} = [session_names{s} ' 100%'];
end

%% --- Task trigger line
hTrigger = xline(10, 'LineWidth', 1.5, 'Color', [0.4 0.4 0.4]);
hTrigger.DisplayName = 'Task trigger';

legend([hPlot hTrigger], [legend_labels {'Task trigger'}], ...
    'Location','northwest', ...
    'FontName','Arial', ...
    'FontSize',8);

%% --- Labels ---
xlabel('Time (s)', 'FontName','Arial','FontSize',11,'FontWeight','bold');
ylabel('Percentage above threshold (%)', 'FontName','Arial','FontSize',11,'FontWeight','bold');

%% --- Axes formatting ---
ax = gca;
ax.FontName   = 'Arial';
ax.FontSize   = 10;
ax.LineWidth  = 2.0;
ax.TickLength = [0.015 0.015];

%% --- Grid ---
grid on
ax.GridColor = [0.5 0.5 0.5];
ax.GridAlpha = 0.15;
ax.XMinorTick = 'on';
ax.YMinorTick = 'on';
ax.MinorGridLineStyle = ':';
ax.MinorGridColor = [0.85 0.85 0.85];
ax.MinorGridAlpha = 0.15;

box on

%% --- Export ---
set(gcf, 'InvertHardcopy', 'off', 'Color', 'w');
set(gcf, 'Renderer', 'painters');

print(gcf, fullfile(outPath, 'ratios_percentage.jpg'), '-djpeg', '-r600');
print(gcf, fullfile(outPath, 'ratios_percentage.svg'), '-dsvg');