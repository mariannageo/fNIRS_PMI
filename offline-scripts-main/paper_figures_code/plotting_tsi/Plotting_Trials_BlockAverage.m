%% POSITIVE MENTAL IMAGERY PILOT DATA - TIME SERIES VISUALIZATION

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
close all; clear all; clc;

% Change working dirctory to the path of the current script
scriptname = mfilename; % name of the current script
spath = which (mfilename); % the location of the current script
cd(erase(spath,[scriptname,'.m'])) % remove the scriptname from the pathname

addpath([pwd '\plotlib']);
PATHPLOTS = pwd;
cd ..;
MAINPATH = pwd;

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                           SELECT MONTAGE
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% Ask user to provide keyboard input for montage selection
% montage types:
% choose 0 for PMI 16x16 montage
% choose 1 for PMI 8x8 montage [coding in progress]
% choose 2 for Motor imagery (SMA) 8x8 setup [still needs to be coded]

mon_select=inputdlg(sprintf('Select your montage. \n 0 for 16X16 PMI \n 1 for 8x8 PMI \n 2 for 8x8 SMA:'));
montage=str2num(mon_select{1});

if montage == 1 || 0
    exp_name='PMI_';
elseif montage == 2
    exp_name='SMA_';
end

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                           SELECT NFB OR LOCALIZER DATA
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

n_data_type=length(dir("online_processed_TSI_data\data\preprocessed"))-3; % get the number of different data types
n_session=length(dir("online_processed_TSI_data\data\preprocessed\localizer"))-2; % get the number of different data types

% choose 0 for localizer
% choose 1 for NFB
for session = 1:n_session
    for data_type = 0:n_data_type

        session_str = num2str(session);

        if data_type == 0
            data_type_str = 'localizer';
            nf_type_str = [];
        elseif data_type == 1
            data_type_str = 'NFB';
            nf_type_str = [];
        elseif data_type == 2 % this data type becomes relevant for GLM; it has no break markers (usually single run recordings)
            data_type_str = 'NFB';
            nf_type_str = ['\' char(inputdlg ('Enter the NF type (ME, CNT, or MI) without space'))]; % user input for the NF type
        end
        %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
        %                               SET PATHES
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

        session_str = num2str(session);
        PATHIN  = [MAINPATH '\online_processed_TSI_data\data\preprocessed\' data_type_str nf_type_str '\S' session_str '\']; % emotion regulation % implement looping over sessions
        PATHOUT = [MAINPATH '\new_plots\block_average_trials_' data_type_str nf_type_str '\S' session_str '\'];

        if ~exist(PATHOUT, 'dir')
            mkdir(PATHOUT)
        end

        %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Load Data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

        filename_data = [exp_name data_type_str '_preprocessed.mat'];
        filename_qt = [exp_name data_type_str '_qt_preprocessed.mat'];

        load([PATHIN, filename_data], 'Hb_SDCcor');
        load([PATHIN, filename_qt], 'ScansQuality');

        %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Plot Data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
        %idx_RDC_hbo = find(strcmp(Hb_SDCcor(1).probe.link.type, 'hbo') & Hb_SDCcor(1).probe.link.ShortSeperation == 0);
        %idx_RDC_hbr = find(strcmp(Hb_SDCcor(1).probe.link.type, 'hbr') & Hb_SDCcor(1).probe.link.ShortSeperation == 0);

        % plot hbo and hbr data together
        job = nirs.modules.BlockAverage;
        job.pre = 5;     % pre stimulus duration (baseline) in sec
        job.post = 25;   % post stimulus duration in sec
        % job.stim_names = {'2'};
        job.stim_names = {'stim_channel2'}; 

        %job.baseline = 'none';   % if no baseline correction is wanted
        HbX_BA = job.run(Hb_SDCcor);

        %%% info: subplot & channel layout looks like this:
        % % chan_layout = [0 0 0 0 0 3 0 0 0 0 0;
        % %                0 0 1 0 2 0 20 0 24 0 0;
        % %                0 0 0 0 0 19 0 0 0 0 0;
        % %                10 0 0 0 5 0 21 0 0 0 25;
        % %                0 11 0 12 0 6 0 23 0 26 0;
        % %                0 0 13 0 4 0 22 0 30 0 0; position 66
        % %                0 0 0 x 0 0 x 0 0 x 0 0;  70, 73, 76
        % %                0 0 0 x 0 0 x 0 0 x 0 0]; 82, 85, 88
        % % check excel file for explanation of the layout
        % % according to his, I created the position vector
        %

        %% dlPFC_chans_left = [2 4 6 10 12 30 54]; % channel indices for HbR dlPFC left
        if montage == 0 % for PMI 16x16 setup; labels read of from optodelayout image file
            % order is solely determined by position on x-y subplot, i.e. we start
            % with S1-D6 and end with S3-D10, overall 25 channels that are
            % plotted (all occipital channels are not plotted so far);
            % arrangement below reflects arrangement of channel in
            % optodelayout plot, with exceptions for SMA that are plotted
            % sequentially
            labels = ["S1-D6", ... % DLPFC (BA 9)
                "S1-D1", "S1-D5", "S9-D6", "S11-D6", ... % DLPFC (BA 9)
                "S9-D5", ... % DLPFC (BA9)
                "S4-D1", "S2-D5", "S9-D7", "S11-D8", ... % DLPFC (BA 9)
                "S4-D2", "S4-D3", "S2-D3", "S2-D7", "S10-D7", "S10-D8", "S12-D8", ... % DLPFC (BA 9 and 46)
                "S4-D4",  "S2-D9", "S13-D7", "S14-D8", ... % SMA and DLPFC (BA 46)
                "S13-D9", ... % SMA
                "S3-D9", "S13-D10", ... % SMA
                "S3-D10"]; % SMA

            sources_enum = [1, ... % DLPFC (BA 9)
                1, 1, 9, 11, ... % DLPFC (BA 9)
                9, ... % DLPFC (BA 9)
                4, 2, 9, 11, ... % DLPFC (BA 9)
                4, 4, 2, 2, 10, 10, 12, ... % DLPFC (BA 9 and 46)
                4, 2, 13, 14, ... % SMA and DLPFC (BA 46)
                13, ... % SMA
                3, 13, ... % SMA
                3]; % SMA

            detector_enum = [6, ...
                1, 5, 6, 6, ...
                5, ...
                1, 5, 7, 8, ...
                2, 3, 3, 7, 7, 8, 8, ...
                4, 9, 7, 8, ...
                9, ...
                9, 10, ...
                10]; % SMA
            % position in subplot to arrange block averages at position from montage optodelayout head surface projection (NIRS site plot)
            % calculated with 11 (X-axis) by 9 (Y-axis) unique positions
            position = [6, ...
                14, 16, 18, 20, ...
                28, ...
                36, 38, 40, 42, ...
                45, 47, 49, 50, 51, 53, 55, ...
                58, 60, 62, 64, ...
                72, ...
                82, 84, ...
                94]; % SMA
            n_rows_suplot = 9;
            n_cols_subplot = 11;
            montage_label = 'PMI 16x16'; % define here for file naming below;
            % for comparison with manual reading from link table
            % probe_link_idx = [6, 2, 4, 56, 68, 56, 68, 54, ... % DLPFC
            %   16, 78, 80, 82, 20, 22]; % SMA
            %for idx = 1:length(probe_link_idx)
            %    probefind(idx_RDC_hbr==probe_link_idx(idx))
            %end
            %indices = [3, 1, 2, 20, 24, 19, 10, 5, 21, 25, 11, 12, 6, 23, 26, 13, 4, 22, 30, ... % DLPFC
            %7, 27, 28, 29, 8, 9]; % SMA
        elseif montage == 1 % for new, reduced PMI 8x8 setup;

            % renamed from 16x16 montage while keeping the same the order (which determined by sequence in subplot) and skipping BA46 channels that are not maintained!
            % now 19 channels
            labels = ["S2-D5", ... % DLPFC (BA 9)
                "S2-D1", "S2-D2", "S5-D5", "S6-D5", ... % DLPFC (BA 9)
                "S5-D2", ... % DLPFC (BA 9)
                "S1-D1", "S3-D2", "S5-D6",  ... % DLPFC (BA 9)
                "S1-D3", "S3-D3", "S3-D6", "S7-D6",... % DLPFC (BA 9 and 46)
                "S3-D4", "S8-D6", ... % SMA and DLPFC (BA 46)
                "S8-D4", ... % SMA
                "S4-D4", "S8-D7", ... % SMA
                "S4-D7"]; % SMA

            sources_enum = [2, ... % DLPFC (BA 9)
                2, 2, 5, 6, ...  % DLPFC (BA 9)
                5, ...  % DLPFC (BA 9)
                1, 3, 5, ...  % DLPFC (BA 9)
                1, 3, 3, 7, ...  % DLPFC (BA 9 and 46)
                3, 8, ... % SMA
                8, ... % SMA
                4, 8, ... % SMA
                4]; % SMA

            detector_enum = [5, ... % DLPFC (BA 9)
                1, 2, 5, 5, ... % DLPFC (BA 9)
                2, ... % DLPFC (BA 9)
                1, 2, 6, ... % DLPFC (BA 9)
                3, 3, 6, 6, ... % DLPFC (BA 9 and 46)
                4, 6, ... % SMA
                4, ... % SMA
                4, 7, ... % SMA
                7]; % SMA

            % reduced 8x8 montage mostly eliminates occipital channels (that were not plotted previously) and some
            % left and right hemisphere DLPFC BA 46 channels, while
            % maintaining all DLPFC BA 9 and SMA channels;
            % position in subplot to arrange block averages at position from montage optodelayout head surface projection (NIRS site plot)
            % copied from 16x16 montage, keeping the same the order (which determined by sequence in subplot) and skipping BA46 channels that are not maintained!
            position = [6, ...
                14, 16, 18, 20, ...
                28, ...
                34, 38, 40, ...
                46, 48, 50, 52, ...
                60, 62, ...
                72, ...
                82, 84, ...
                94]; % SMA
            n_rows_suplot = 9; %% could possibly be adapted as montage is smaller than 16x16???
            n_cols_subplot = 11; %% could possibly be adapted as montage is smaller than 16x16???
            montage_label = 'PMI 8x8'; % define here for file naming below;

        elseif montage == 2 % position still needs to be coded for SMA montage
            labels = ["S1-D1", "S1-D2", "S2-D2", ...
                "S3-D1", "S1-D4", "S4-D2", "S2-D5", ...
                "S3-D3", "S3-D4", "S4-D4", "S4-D5", "S5-D5", ...
                "S3-D6", "S6-D4", "S4-D7", "S7-D5", ...
                "S6-D6", "S6-D7", "S7-D7"];
            % in total 19 channels
            sources_enum = [1, 1, 2, ... % 3 chans
                3, 1, 4, 2, ... % 4 chans
                3, 3, 4, 4, 5, ... % 5 chans
                3, 6, 4, 7, ... % 4 chans
                6, 6, 7]; % 3 chans

            detector_enum = [1, 2, 2, ...
                1, 4, 2, 5, ...
                3, 4, 5, 5, 5, ...
                6, 4, 7, 5, ...
                6, 7, 7];

            position = [3, 5, 7, ... % continues numbers from 1 to 45, determines position in subplot
                11, 13, 15, 17, ...
                19, 21, 23, 25, 27, ...
                29, 31, 33, 35, ...
                39, 41, 43]; % 9 x 5 plot, based on montage arrangement
            n_rows_suplot = 5;
            n_cols_subplot = 9;
            montage_label = 'Motor Imagery';
        end

        idx_RDC_hbo = [];
        idx_RDC_hbr = [];
        for chan = 1:length(sources_enum)
            chan_idx=find(Hb_SDCcor(1).probe.link.source==sources_enum(chan) & Hb_SDCcor(1).probe.link.detector==detector_enum(chan) & ...
                strcmp(Hb_SDCcor(1).probe.link.type, 'hbo') & Hb_SDCcor(1).probe.link.ShortSeperation == 0);
            idx_RDC_hbo = [idx_RDC_hbo; chan_idx]; % HbO
            chan_idx=find(Hb_SDCcor(1).probe.link.source==sources_enum(chan) & Hb_SDCcor(1).probe.link.detector==detector_enum(chan) & ...
                strcmp(Hb_SDCcor(1).probe.link.type, 'hbr') & Hb_SDCcor(1).probe.link.ShortSeperation == 0);
            idx_RDC_hbr = [idx_RDC_hbr; chan_idx]; % HbR
        end
        % for comparison with manual reading from link table
        % probe_link_idx = [6, 2, 4, 56, 68, 56, 68, 54, ... % DLPFC
        %   16, 78, 80, 82, 20, 22]; % SMA
        %for idx = 1:length(probe_link_idx)
        %    probefind(idx_RDC_hbr==probe_link_idx(idx))
        %end
        %indices = [3, 1, 2, 20, 24, 19, 10, 5, 21, 25, 11, 12, 6, 23, 26, 13, 4, 22, 30, ... % DLPFC
        %7, 27, 28, 29, 8, 9]; % SMA
        % position = [6, 14, 16, 18, 20, 28, 34, 38, 40, 44, 46, 48, 50, 52, 54, 58, 60, 62, 64, ... % DLPFC
        %     70, 73, 76, 82, 85, 88]; % SMA
        % labels = ["S1-D6", "S1-D1", "S1-D5", "S9-D6", "S11-D6", "S9-D5", "S4-D1", "S2-D5", "S9-D7", ...
        %     "S11-D8", "S4-D2", "S4-D3", "S2-D7", "S10-D8", "S12-D8", "S4-D4", "S2-D3", "S10-D7", "S14-D8", ... % DLPFC
        %     "S2-D9", "S13-D7", "S13-D9", "S13-D10", "S3-D9", "S3-D10"]; % SMA

        % t = linspace(-5, 25, size(HbX_BA.stim_2_allSubj_BA, 1));
        t = linspace(-job.pre, job.post, size(HbX_BA.stim_stim_channel2_allSubj_BA, 1)); % murat on 24/6/25


        %% group plots
        figure;
        for ch = 1:length(idx_RDC_hbo) % previous version looped over "indices"
            %ch = indices(ch);

            subplot(n_rows_suplot, n_cols_subplot, position(ch)); % expand to 8
            hold on
            % hbo
            %curve1 = HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbo(ch))' + nanstd(HbX_BA.stim_2_indiv_BA(:, :, idx_RDC_hbo(ch)))./sqrt(size(HbX_BA.stim_2_indiv_BA, 1));
            %curve2 = HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbo(ch))' - nanstd(HbX_BA.stim_2_indiv_BA(:, :, idx_RDC_hbo(ch)))./sqrt(size(HbX_BA.stim_2_indiv_BA, 1));

            % old ones
            % curve1 = HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbo(ch))' + nanstd(HbX_BA.stim_2_indiv_BA(:, :, idx_RDC_hbo(ch)), 0, 1)./sqrt(size(HbX_BA.stim_2_indiv_BA, 1)); % enforce first dimension for single-subject case
            % curve2 = HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbo(ch))' - nanstd(HbX_BA.stim_2_indiv_BA(:, :, idx_RDC_hbo(ch)), 0, 1)./sqrt(size(HbX_BA.stim_2_indiv_BA, 1));
            % for tsi
            curve1 = HbX_BA.stim_stim_channel2_allSubj_BA(:, idx_RDC_hbo(ch))' + nanstd(HbX_BA.stim_stim_channel2_indiv_BA(:, :, idx_RDC_hbo(ch)), 0, 1)./sqrt(size(HbX_BA.stim_stim_channel2_indiv_BA, 1)); % enforce first dimension for single-subject case
            curve2 = HbX_BA.stim_stim_channel2_allSubj_BA(:, idx_RDC_hbo(ch))' - nanstd(HbX_BA.stim_stim_channel2_indiv_BA(:, :, idx_RDC_hbo(ch)), 0, 1)./sqrt(size(HbX_BA.stim_stim_channel2_indiv_BA, 1));

            x2 = [t, fliplr(t)];
            inBetween = [curve1, fliplr(curve2)];
            fill(x2, inBetween, [248, 105, 35]./255, 'FaceAlpha', 0.3, 'EdgeColor','none');

            % hbr
            % old ones
            % curve1 = HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbr(ch))' + nanstd(HbX_BA.stim_2_indiv_BA(:, :, idx_RDC_hbr(ch)), 0, 1)./sqrt(size(HbX_BA.stim_2_indiv_BA, 1));
            % curve2 = HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbr(ch))' - nanstd(HbX_BA.stim_2_indiv_BA(:, :, idx_RDC_hbr(ch)), 0, 1)./sqrt(size(HbX_BA.stim_2_indiv_BA, 1));
            % for tsi
            curve1 = HbX_BA.stim_stim_channel2_allSubj_BA(:, idx_RDC_hbr(ch))' + nanstd(HbX_BA.stim_stim_channel2_indiv_BA(:, :, idx_RDC_hbr(ch)), 0, 1)./sqrt(size(HbX_BA.stim_stim_channel2_indiv_BA, 1));
            curve2 = HbX_BA.stim_stim_channel2_allSubj_BA(:, idx_RDC_hbr(ch))' - nanstd(HbX_BA.stim_stim_channel2_indiv_BA(:, :, idx_RDC_hbr(ch)), 0, 1)./sqrt(size(HbX_BA.stim_stim_channel2_indiv_BA, 1));

            x2 = [t, fliplr(t)];
            inBetween = [curve1, fliplr(curve2)];
            fill(x2, inBetween, [102, 134, 176]./255, 'FaceAlpha', 0.3, 'EdgeColor','none');

            % hbo
            % plot(t, HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbo(ch)), 'Color', [248, 105, 35]./255, 'LineWidth', 4);
            plot(t, HbX_BA.stim_stim_channel2_allSubj_BA(:, idx_RDC_hbo(ch)), 'Color', [248, 105, 35]./255, 'LineWidth', 4);
            % hbr
            % plot(t, HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbr(ch)), 'Color', [102, 134, 176]./255, 'LineWidth', 4);
            plot(t, HbX_BA.stim_stim_channel2_allSubj_BA(:, idx_RDC_hbr(ch)), 'Color', [102, 134, 176]./255, 'LineWidth', 4);

            title(labels(ch), 'FontSize', 16);


            % ylim([min(min([HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbo), HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbr)]))-0.15, ...
                % max(max([HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbo), HbX_BA.stim_2_allSubj_BA(:, idx_RDC_hbr)]))+0.2])
              %tsi
%  M            ylim([min(min([HbX_BA.stim_stim_channel2_allSubj_BA(:, idx_RDC_hbo), HbX_BA.stim_stim_channel2_allSubj_BA(:, idx_RDC_hbr)]))-0.15, ...
%                 max(max([HbX_BA.stim_stim_channel2_allSubj_BA(:, idx_RDC_hbo), HbX_BA.stim_stim_channel2_allSubj_BA(:, idx_RDC_hbr)]))+0.2])

            yline(0, 'k')
            xline(0, 'k')
            xline(15, 'k')
            set(gca,'xtick',[])
        end

        % create legend
        Lgnd = legend('','Location', 'eastoutside');
        Lgnd.Position(1) = 0.01;
        Lgnd.Position(2) = 0.4;
        Lgnd.FontSize = 14;   %by Marianna     
        cols = [([248, 105, 35]./255); ([102, 134, 176]./255)];
        col_names = ["HbO", "HbR"];
        for j =1:length(col_names)
            plot([NaN NaN], [NaN NaN], 'Color', cols(j,:), 'DisplayName', col_names(j),'LineWidth', 4);
        end

        % title and settings
        sgtitle([exp_name nf_type_str ' block averages, mean subjects, ' data_type_str], 'FontSize', 20);
        set(gcf,'PaperUnits','inches','PaperPosition',[0 0 20 15])
        print('-dpng', [PATHOUT, montage_label, 'PMI_BA.png']);
        close all

        %% single subject plots

        prev_sub=[];

        for sub = 1:size(Hb_SDCcor, 1)
            figure;
            curr_sub = strsplit(Hb_SDCcor(sub,1).description, '\');
            curr_sub = curr_sub{end-1};

            if strcmp(prev_sub,curr_sub)
                no_run=no_run+1;
                prev_sub=curr_sub;
            else
                no_run=1;
                prev_sub=curr_sub;
            end
            for ch = 1:length(idx_RDC_hbo) % previous version looped over "indices"

                %curr_idx = indices(ch);
                curr_HbO_chan = idx_RDC_hbo(ch);
                curr_HbR_chan = idx_RDC_hbr(ch);

                % if channel would be pruned (bad signal quality), change title color
                % to red
                title_color = '\color{black}';

                % if HbO or HbR channels would have been pruned based on qt
                % (usually both are pruned)
                if(~ScansQuality(1,sub).qMats.MeasListAct(curr_HbO_chan) || ...
                        ~ScansQuality(1,sub).qMats.MeasListAct(curr_HbR_chan))
                    title_color = '\color{red}';
                end

                subplot(n_rows_suplot, n_cols_subplot, position(ch))
                hold on
                % hbo
                % plot(t, squeeze(HbX_BA.stim_2_indiv_BA(sub, :, curr_HbO_chan)), 'Color', [248, 105, 35]./255, 'LineWidth', 4);
                plot(t, squeeze(HbX_BA.stim_stim_channel2_indiv_BA(sub, :, curr_HbO_chan)), 'Color', [248, 105, 35]./255, 'LineWidth', 4);
                % hbr
                % plot(t, squeeze(HbX_BA.stim_2_indiv_BA(sub, :, curr_HbR_chan)), 'Color', [102, 134, 176]./255, 'LineWidth', 4);
                plot(t, squeeze(HbX_BA.stim_stim_channel2_indiv_BA(sub, :, curr_HbR_chan)), 'Color', [102, 134, 176]./255, 'LineWidth', 4);
                title([title_color labels(ch)], 'FontSize', 14);

                % ylim([min(min(min([squeeze(HbX_BA.stim_2_indiv_BA(:, :, idx_RDC_hbo)), ...
                    % squeeze(HbX_BA.stim_2_indiv_BA(:, :, idx_RDC_hbr))]))), ...
                    % max(max(max([squeeze(HbX_BA.stim_2_indiv_BA(:, :, idx_RDC_hbo)), ...
                    % squeeze(HbX_BA.stim_2_indiv_BA(:, :, idx_RDC_hbr))])))])

%         M        ylim([min(min(min([squeeze(HbX_BA.stim_stim_channel2_indiv_BA(:, :, idx_RDC_hbo)), ...
%                     squeeze(HbX_BA.stim_stim_channel2_indiv_BA(:, :, idx_RDC_hbr))]))), ...
%                     max(max(max([squeeze(HbX_BA.stim_stim_channel2_indiv_BA(:, :, idx_RDC_hbo)), ...
%                     squeeze(HbX_BA.stim_stim_channel2_indiv_BA(:, :, idx_RDC_hbr))])))])


                yline(0, 'k')
                xline(0, 'k')
                xline(15, 'k')
                set(gca,'xtick',[])
                %         set(gca,'ytick',[])
            end

            % create legend
            Lgnd = legend('','Location', 'eastoutside');
            Lgnd.Position(1) = 0.01;
            Lgnd.Position(2) = 0.4;
            Lgnd.FontSize = 14;            
            cols = [([248, 105, 35]./255); ([102, 134, 176]./255)];
            col_names = ["HbO", "HbR"];
            for j =1:length(col_names)
                plot([NaN NaN], [NaN NaN], 'Color', cols(j,:), 'DisplayName', col_names(j),'LineWidth', 4);
            end

            sgtitle({[exp_name nf_type_str ' Subject: ' curr_sub(2:end) ' Run: ' num2str(no_run)], ...
                'Channels in red have bad signal quality, will be pruned. ', data_type_str}, 'FontSize', 18);
            set(gcf,'PaperUnits','inches','PaperPosition', [0 0 20 15])
            print('-dpng', [PATHOUT, montage_label, 'PMI_BA_s', num2str(curr_sub(2:end)), '_run_' num2str(no_run), '.png']);
            close all
        end
    end
end