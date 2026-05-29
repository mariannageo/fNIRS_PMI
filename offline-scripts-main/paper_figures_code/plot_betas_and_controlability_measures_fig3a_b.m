%% ==================================================================================================================
%% Plotting of run-averaged beta values and controllability scores across sessions, Figure 3A,B
%% ==================================================================================================================
% Created by Marianna Georgiou
% Department of Psychiatry, Psychotherapy and Psychosomatics, University Hospital RWTH Aachen, Aachen, Germany
% email: mariannag43@gmail.com

clear all; close all;

%% Load data
% NOTE: adapt paths to local environment
filename = '\offline-scripts-main\paper_figures_data\hbr_betas_average_NFB_channs.xlsx';
filename2 = '\offline-scripts-main\paper_figures_data\subjective_controlability.xlsx';
outPath = '\offline-scripts-main\paper_figures_data\plots';

dataTable = readtable(filename);

%% Extract relevant columns
cols = {'Localizer_S1','NFB_S1','Localizer_S2','NFB_S2','Localizer_S3','NFB_S3', 'Localizer_S4'};
data = dataTable{:, cols};

%% Colors (Palette 3)
green_loc = [0.56 0.69 0.60];   % Sage Green
grey_nfb  = [0.29 0.29 0.29];   % Slate Grey

%% Box positions
positions = [1 2 4 5 7 8 9];  % last one is Post-test Loc

%% Create figure
figure('Units','inches','Position',[1 1 6.75 4],'Color','w');
hold on

%% Create boxplot without symbols
h = boxplot(data, 'Positions', positions, 'Widths', 0.7, 'Colors', 'k', 'Symbol', '');

%% Correct order of boxes for coloring
boxes = findobj(h,'Tag','Box'); 
boxes = flipud(boxes);  % ensures left-to-right order matches data

%% Define colors for each column
colors = [green_loc; grey_nfb; green_loc; grey_nfb; green_loc; grey_nfb; green_loc];

%% Fill boxes with colors
for j = 1:length(boxes)
    patch(get(boxes(j),'XData'), get(boxes(j),'YData'), colors(j,:), ...
          'FaceAlpha',0.8, 'EdgeColor','k', 'LineWidth',0.8);
end

%% Overlay individual points
for i = 1:length(positions)
    x = positions(i)*ones(size(data(:,i)));
    y = data(:,i);
    scatter(x, y, 26, 'MarkerFaceColor', [0.2 0.2 0.2], ...
            'MarkerEdgeColor','none', 'MarkerFaceAlpha',0.55);
end
xticks(positions);
xticklabels(["Loc S1","NFB S1","Loc S2","NFB S2","Loc S3","NFB S3", "    Post-Train" + newline + 'run']);

ax = gca;
ax.XTickLabelRotation = 0;

%% Axis labels
ylabel('\bf GLM \beta \Delta[HbR]', 'FontName','Arial','FontSize',11);
xlabel('Condition per Session','FontSize',11,'FontWeight','bold','FontName','Arial');

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
%ylim([min(data(:))-0.2 max(data(:))+0.2]);
ylim([-1 1])

%% Optimized Export for SPIE
% Set the background to white explicitly before export
set(gcf, 'InvertHardcopy', 'off', 'Color', 'w');

% Force the renderer to Painters for true vector graphics
set(gcf, 'Renderer', 'painters');
% Export high-res JPG for quick viewing
print(gcf, fullfile(outPath,'Beta_Boxplots.jpg'), '-djpeg', '-r600');

% Export SVG for the final paper
print(gcf, fullfile(outPath,'Beta_Boxplot.svg'), '-dsvg');

%% -------------------------------
%% Subjective controllability figure 
%% -------------------------------

% Load Excel file
controlTable = readtable(filename2);

% Exclude row where Subject ID is 21
controlTable(controlTable.SubjectID == 21, :) = [];

% Extract relevant columns
cols2 = {'S1','S2','S3'};
data2 = controlTable{:, cols2};

%% Prepare boxplot positions
positions2 = [1 2 3];
%% Create figure
% Pastel blue color for boxes
blue_new = [0.49 0.66 0.82];  

figure('Units','inches','Position',[1 1 2.5 3],'Color','w'); 
hold on

% Create boxplots without default symbols
h = boxplot(data2, 'Positions', positions2, 'Widths', 0.7, 'Colors', 'k', 'Symbol', '');

% Correct box order for coloring
boxes = findobj(h,'Tag','Box'); 
boxes = flipud(boxes);

% Fill boxes with pastel blue
for j = 1:length(boxes)
    patch(get(boxes(j),'XData'), get(boxes(j),'YData'), blue_new, ...
          'FaceAlpha',0.8, 'EdgeColor','k', 'LineWidth',0.8);
end

% Overlay individual data points
for i = 1:length(positions2)
    x = positions2(i)*ones(size(data2(:,i)));
    y = data2(:,i);
    scatter(x, y, 26, 'MarkerFaceColor', [0.2 0.2 0.2], ...
            'MarkerEdgeColor','none', 'MarkerFaceAlpha',0.55);
end

%% X-axis labels
xticks(positions2);
xticklabels({'S1','S2','S3'});

%% Labels
ylabel('Subjective controllability (%)', 'FontSize',11, 'FontWeight','bold', 'FontName','Arial');
xlabel('Sessions', 'FontSize',11, 'FontWeight','bold', 'FontName','Arial');

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
ylim([min(data2(:))-5 max(data2(:))+5]); % margin for points

%% Export figure

set(gcf, 'InvertHardcopy', 'off', 'Color', 'w');

% Force the renderer to Painters for true vector graphics
set(gcf, 'Renderer', 'painters');

% Export high-res JPG for quick viewing
print(gcf, fullfile(outPath,'Subjective_Controlability.jpg'), '-djpeg', '-r600');

% Export SVG for the final paper
print(gcf, fullfile(outPath,'Subjective_Controlability.svg'), '-dsvg');