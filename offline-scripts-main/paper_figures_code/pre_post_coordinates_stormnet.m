
%% ========================================================================================================================================================
%  DERS Stats: Mean, STD, Wilcoxon, Bonferroni
% ================================================================================================================================================================
clc; clear; close all;

outPath = '\offline-scripts-main\paper_figures_data\plots';

for s = 1:3
    basePath = ['\offline-scripts-main\paper_figures_data\STORM-Net\S' num2str(s)];



    participants = dir(fullfile(basePath, 'P*'));
    participants = participants([participants.isdir]);

    % Optodes of interest
    %Information about the optodes and the procedure is found here https://github.com/yoterel/STORM-Net

    optodesToKeep = {...   %%%% Cz to frontal
        'fpz','nasion','top','fp1','af7','af3','f5','left_triangle','lpa', ...
        'fp2','af4','af8','f6','right_triangle','middle_triangle','cz','c4', ...
        'lefteye','righteye','nosetip'};

    allDX = [];
    allDY = [];
    allDZ = [];
    allDistances = [];
    participantNames = {};

    validIndex = 0;

    %% ===============================
    %% LOAD DATA
    %% ===============================

    for p = 1:length(participants)

        participantPath = fullfile(basePath, participants(p).name);

        preFolder  = fullfile(participantPath, '1');
        postFolder = fullfile(participantPath, '2');

        preFile  = dir(fullfile(preFolder, '*_pre*'));
        postFile = dir(fullfile(postFolder, '*_post*'));

        if isempty(preFile) || isempty(postFile)
            continue;
        end

        file1 = fullfile(preFolder,  preFile(1).name);
        file2 = fullfile(postFolder, postFile(1).name);

        data1 = readtable(file1,'FileType','text','Delimiter',' ','ReadVariableNames',false);
        data2 = readtable(file2,'FileType','text','Delimiter',' ','ReadVariableNames',false);

        % Filter optodes
        mask1 = ismember(data1.Var1, optodesToKeep);
        mask2 = ismember(data2.Var1, optodesToKeep);

        data1_filtered = data1(mask1,:);
        data2_filtered = data2(mask2,:);

        % Match optodes order
        [~, idx1, idx2] = intersect(data1_filtered.Var1, data2_filtered.Var1,'stable');

        coords1 = [data1_filtered.Var2(idx1) data1_filtered.Var3(idx1) data1_filtered.Var4(idx1)];
        coords2 = [data2_filtered.Var2(idx2) data2_filtered.Var3(idx2) data2_filtered.Var4(idx2)];

        if validIndex == 0
            electrodeNames = data1_filtered.Var1(idx1);
        end

        %Displacements in x,y,z directions
        diffCoords = coords1 - coords2;

        dx = diffCoords(:,1);
        dy = diffCoords(:,2);
        dz = diffCoords(:,3);

        %Euclidean distance
        dist = sqrt(dx.^2 + dy.^2 + dz.^2);

        validIndex = validIndex + 1;

        allDX(:,validIndex) = dx;
        allDY(:,validIndex) = dy;
        allDZ(:,validIndex) = dz;
        allDistances(:,validIndex) = dist;

        participantNames{validIndex} = participants(p).name;

    end

    numParticipants = size(allDX,2);

    %% ===============================
    %% BOXPLOTS PER PARTICIPANT
    %% ===============================

    rows = ceil(sqrt(numParticipants));
    cols = ceil(numParticipants / rows);

    figure('Color','w','Position',[100 100 1000 700]);

    for p = 1:numParticipants

        subplot(rows,cols,p);

        data = [allDX(:,p), allDY(:,p), allDZ(:,p), allDistances(:,p)];

        h = boxplot(data, ...
            'Labels', {'Disp. X','Disp. Y','Disp. Z','Eucl. Dist'}, ...
            'Symbol','k.', ...
            'Colors','k', ...
            'Whisker',1.5);


        % Make box lines bold and black
        set(findobj(gca,'Tag','Box'), 'LineWidth', 1.2, 'Color', 'k');

        % Make whiskers bold
        set(findobj(gca,'Tag','Whisker'), 'LineWidth', 1.2, 'Color', 'k');

        % Make caps bold
        set(findobj(gca,'Tag','Cap'), 'LineWidth', 1.2, 'Color', 'k');

        % Make median line slightly thicker (optional)
        set(findobj(gca,'Tag','Median'), 'LineWidth', 1.2, 'Color', 'r');



        title(participantNames{p}, 'FontSize', 11, 'Interpreter','none');

        ylabel('Distance (mm)', 'FontSize', 10);

        grid on;
        set(gcf, 'Renderer', 'painters');

        %% Axes formatting
        ax = gca;
        ax.FontName   = 'Arial';
        ax.FontSize   = 10;
        %ax.FontWeight = 'bold';
        ax.LineWidth  = 1.5;         % bold frame
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
        ax = gca;
        ax.XTickLabelRotation = 0;

        %% Box and limits
        box on

        %     set(gca, ...
        %         'FontSize', 9, ...
        %         'LineWidth', 1, ...
        %         'Box','off');

    end

    %% ====================================================================
    %% FIGURE TITLE + EXPORT
    %% ====================================================================

    sgtitle( ...
        ['Optodes Displacement (Pre vs post session) - S' num2str(s)], ...
        'FontSize',11, ...
        'FontWeight','bold');

    set(gcf, 'InvertHardcopy', 'off', 'Color', 'w');

 

   

    %% ===============================
    %% GLOBAL STATISTICS
    %% ===============================

    dx_all = allDX(:);
    dy_all = allDY(:);
    dz_all = allDZ(:);
    dist_all = allDistances(:);

    fprintf('\n===== GLOBAL STATISTICS =====\n');
    fprintf('Mean Euclidean Distance: %.3f mm\n', mean(dist_all));
    fprintf('Median Euclidean Distance: %.3f mm\n', median(dist_all));
    fprintf('Max Euclidean Distance: %.3f mm\n', max(dist_all));

    %% ===============================
    %% THRESHOLD ANALYSIS (> 10 mm)
    %% ===============================

    threshold = 10;

    fprintf('\n===== OPTODES WITH DISTANCE > %.1f mm =====\n', threshold);

    exceedMatrix = allDistances > threshold;

    for p = 1:numParticipants
        for e = 1:size(allDistances,1)
            if exceedMatrix(e,p)
                fprintf('Participant %s | Optode %s | Distance = %.2f mm\n', ...
                    participantNames{p}, electrodeNames{e}, allDistances(e,p));
            end
        end
    end

    percentAbove = 100 * sum(exceedMatrix(:)) / numel(exceedMatrix);
    fprintf('\nPercentage of all measurements > %.1f mm: %.2f %%\n', threshold, percentAbove);

end
