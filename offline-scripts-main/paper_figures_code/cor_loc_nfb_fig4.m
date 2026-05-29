
%% =========================================================
%% Correlation between Localizer and Neurofeedback GLM betas
%% =========================================================
%
% Description:
% This script assesses the relationship between GLM beta values extracted
% from the Localizer and Neurofeedback (NFB) conditions across sessions.
%
% For each session (S1–S3), participant-level beta values are correlated
% between Localizer and NFB using Spearman’s rank correlation.
%
% Output:
% - Scatter plots per session (S1–S3)
% - Linear regression fit overlaid for visualization
% - Correlation coefficients (ρ) and p-values displayed per panel
% - Publication-quality figure exported as .JPG and .SVG
%
% Created by Marianna Georgiou
% Department of Psychiatry, Psychotherapy and Psychosomatics, 
% University Hospital RWTH Aachen, Aachen, Germany
% email: mariannag43@gmail.com
%% =========================================================
clear; close all; clc

%% Setup
colors = [0 0 0; 0.5 0.5 0.5; 0.8 0.2 0];

%% Load Data
% NOTE: adapt paths to local environment
data = readtable('\offline-scripts-main\paper_figures_data\hbr_betas_average_NFB_channs.xlsx');
outPath = '\offline-scripts-main\paper_figures_data\plots';

participants = data.Participant;

loc = [data.Localizer_S1, data.Localizer_S2, data.Localizer_S3];
nfb = [data.NFB_S1, data.NFB_S2, data.NFB_S3];

%% Panel Figure
figure('Units','inches','Position',[1 1 6.75 3.4],'Color','w');

for sess = 1:3

    subplot(1,3,sess)
    hold on

    %% Correlation
    [r,p] = corr(loc(:,sess), nfb(:,sess), 'Type','Spearman');

    %% Scatter
    scatter(loc(:,sess), nfb(:,sess), 50, ...
        'MarkerFaceColor', colors(sess,:), ...
        'MarkerEdgeColor','none', ...
        'MarkerFaceAlpha',0.75);

    %% Reference lines
    xline(0,'k--','LineWidth',1.2)
    yline(0,'k--','LineWidth',1.2)

    %% Extended regression line
    mdl = fitlm(loc(:,sess), nfb(:,sess));
    x_range = linspace(min(loc(:,sess))-0.4, max(loc(:,sess))+0.4, 100);
    y_pred = predict(mdl, x_range');

    plot(x_range, y_pred, ...
        'Color',[0.15 0.15 0.15], ...
        'LineWidth',2);

    %% Participant labels
    for i = 1:length(participants)
        text(loc(i,sess), nfb(i,sess), participants{i}, ...
            'FontSize',7, ...
            'Color',[0.25 0.25 0.25], ...
            'VerticalAlignment','bottom', ...
            'HorizontalAlignment','right');
    end

    %% Y label only first subplot
    if sess == 1
        ylabel('NFB \beta \Delta[HbR]', ...
            'FontSize',10,'FontWeight','bold','FontName','Arial');
    end

    %% X label only middle subplot
    if sess == 2
        xlabel('Localizer \beta \Delta[HbR]', ...
            'FontSize',10,'FontWeight','bold','FontName','Arial');
    end

    %% Subplot title
    title(sprintf('S%d',sess), ...
        'FontSize',11, ...
        'FontWeight','bold', ...
        'FontName','Arial');

    %% Correlation annotation
    text(0.05,0.92, ...
        sprintf('\\rho = %.2f\np = %.3f', r, p), ...
        'Units','normalized', ...
        'FontSize',10, ...
        'FontName','Arial');

    %% Axes formatting
    ax = gca;
    ax.FontName   = 'Arial';
    ax.FontSize   = 10;
    %ax.FontWeight = 'bold';
    ax.LineWidth  = 2.0;         % bold frame
    ax.TickLength = [0.015 0.015];

    %% Grid (thin and subtle)
    grid on
    ax.GridColor     = [0.5 0.5 0.5];  % light gray
    ax.GridAlpha     = 0.15;           % semi-transparent
    ax.XMinorTick    = 'on';
    ax.YMinorTick    = 'on';
    ax.MinorGridLineStyle = ':';
    ax.MinorGridColor = [0.85 0.85 0.85];
    ax.MinorGridAlpha = 0.15;

    %% Box and limits
    box on

    %% Limits
    %xlim([min(loc(:,sess))-0.45 max(loc(:,sess))+0.45])
    xlim([-1 1])

    %ylim([min(nfb(:,sess))-0.45 max(nfb(:,sess))+0.45])
    ylim([-1 1])


end



set(gcf, 'InvertHardcopy', 'off', 'Color', 'w');

set(gcf, 'Renderer', 'painters');
print(gcf, fullfile(outPath,'Correlation_Localizer_vs_NFB_panel_FINAL.jpg'), '-djpeg', '-r600');
print(gcf, fullfile(outPath,'Correlation_Localizer_vs_NFB_panel_FINAL.svg'), '-dsvg');

%% =========================================================
%% Run averaged betas across sessions for Subgroup1 and Subgroup 2
%% Subgroup 1: %participants showing negative Localizer and NFB betas in at least 2 of 3 training sessions
%% Subgroup 2: The rest participants
%% =========================================================
%% Load data
participants = data.Participant;

loc_s1 = data.Localizer_S1;
loc_s2 = data.Localizer_S2;
loc_s3 = data.Localizer_S3;
loc_s4 = data.Localizer_S4;

nfb_s1 = data.NFB_S1;
nfb_s2 = data.NFB_S2;
nfb_s3 = data.NFB_S3;

%% Grouping
group1 = {};
groupRest = {};

for i = 1:length(participants)
    loc_vals = [loc_s1(i), loc_s2(i), loc_s3(i)];
    nfb_vals = [nfb_s1(i), nfb_s2(i), nfb_s3(i)];

    if sum(loc_vals < 0) >= 2 && sum(nfb_vals < 0) >= 2
        group1{end+1} = participants{i};
    else
        groupRest{end+1} = participants{i};
    end
end

groups = struct( ...
    'name', {'Subgroup 1','Subgroup 2'}, ...
    'participants', {group1,groupRest} ...
    );


%% Colors
blue_loc = [0.49 0.66 0.82];
red_nfb  = [0.85 0.4 0.4];

positions = 1:7;

%% Loop groups
for g = 1:length(groups)

    idx = ismember(participants, groups(g).participants);
    if sum(idx)==0
        continue
    end

    %% Prepare matrix in desired order
    data_mat = [ ...
        loc_s1(idx), ...
        nfb_s1(idx), ...
        loc_s2(idx), ...
        nfb_s2(idx), ...
        loc_s3(idx), ...
        nfb_s3(idx), ...
        loc_s4(idx)];

    figure('Units','inches','Position',[1 1 6.75 4],'Color','w');
    hold on

    %% Boxplot
    h = boxplot(data_mat, ...
        'Positions',positions, ...
        'Widths',0.6, ...
        'Colors','k', ...
        'Symbol','');

    boxes = findobj(h,'Tag','Box');
    boxes = flipud(boxes);

    %% Color boxes alternating
    for j = 1:length(boxes)

        if ismember(j,[1 3 5 7]) % Localizer boxes
            col = blue_loc;
        else
            col = red_nfb;
        end

        patch(get(boxes(j),'XData'),get(boxes(j),'YData'),col,...
            'FaceAlpha',0.8,'EdgeColor','k','LineWidth',0.8);
    end

    %% Scatter overlay
    for i = 1:7
        scatter(positions(i)*ones(sum(idx),1), ...
            data_mat(:,i), ...
            24,'MarkerFaceColor',[0.2 0.2 0.2], ...
            'MarkerEdgeColor','none', ...
            'MarkerFaceAlpha',0.55);
    end

    %% Labels
    xticks(positions)
    xticklabels(["Loc S1", "NFB S1", "Loc S2", "NFB S2", "Loc S3", "NFB S3", "    Post-Train" + newline + 'run']);    ax = gca;
    ax.XTickLabelRotation = 0;

    ylabel('\beta \Delta[HbR]', ...
        'FontSize',11,'FontWeight','bold','FontName','Arial');

    xlabel('Task per Session', ...
        'FontSize',11,'FontWeight','bold','FontName','Arial');

    %% Axes style
    ax = gca;
    ax.FontName   = 'Arial';
    ax.FontSize   = 10;
    %ax.FontWeight = 'bold';
    ax.LineWidth  = 2.0;         % bold frame
    ax.TickLength = [0.015 0.015];

    %% Grid (thin and subtle)
    grid on
    ax.GridColor     = [0.5 0.5 0.5];  % light gray
    ax.GridAlpha     = 0.15;           % semi-transparent
    ax.XMinorTick    = 'on';
    ax.YMinorTick    = 'on';
    ax.MinorGridLineStyle = ':';
    ax.MinorGridColor = [0.85 0.85 0.85];
    ax.MinorGridAlpha = 0.15;

    %% Box and limits
    box on

    %% Limits
    %ylim([min(data_mat(:))-0.4 max(data_mat(:))+0.4]);
    ylim([-1 1])

    %% Title
    title(sprintf('%s (N = %d)',groups(g).name,sum(idx)), ...
        'FontSize',13,'FontWeight','bold','FontName','Arial');

    set(gcf, 'Renderer', 'painters');

    jpgName = sprintf('%s_LOCvsNFB_sequential.jpg', groups(g).name);
    print(gcf, fullfile(outPath, jpgName), '-djpeg', '-r600');

    % 3. Export SVG for the final paper
    svgName = sprintf('%s_Correlation_Localizer_vs_NFB_panel_FINAL.svg', groups(g).name);
    print(gcf, fullfile(outPath, svgName), '-dsvg');

    
end