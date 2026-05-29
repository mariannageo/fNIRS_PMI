% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                              - BASED ON -                               %
%%    A Hitchhiker's Guide to fNIRS Data Analysis %%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% Created by Franziska Klein a,b,c edited by Marianna Georgiou a, Murat C.
% Mutlu a
% and David Mehler a,b,d
% a Department of Psychiatry, Psychotherapy and Psychosomatics, University Hospital RWTH Aachen, Aachen, Germany
% b Biomedical Devices and Systems Group, R&D Division Health, OFFIS - Institute for Information Technology, Oldenburg, Germany
% c Assistive Systems and Medical Device Technology Group, Department of Health Services Research, University of Oldenburg, Oldenburg, Germany
% d School of Psychology, Cardiff University Brain Research Imaging Center (CUBRIC), Cardiff University, Cardiff, UK

% Using Matlab 2021b

%This script processes Localizer TSI processed data, not RAW!

% What you need:
%
% NIRS Brain AnalyzIR Toolbox: https://github.com/huppertt/nirs-toolbox
% QT-NIRS: https://github.com/lpollonini/qt-nirs
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%% POSITIVE MENTAL IMAGERY - PREPROCESSING
%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

close all; clear all; clc;

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%             CHANGE PATH to THE FOLDER OF THE CURRENT SCRIPT
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
scriptname = mfilename; % name of the current script
spath = which (mfilename); % the location of the current script
cd(erase(spath,[scriptname,'.m'])) % remove the scriptname from the pathname
addpath([pwd '\lib_tsi']); % add function/script libraries to the path
MAINPATH = pwd; %offline-scripts-main
DATAPATH = '\Data'; %Download the data, avalible here ---> [], please include the data folder into the offline-scripts-main folder



%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                               Get paths
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
aur_data_path=[DATAPATH '\Raw\Localizer'];
tsi_data_path=[DATAPATH '\Matlab\Localizer'];

%exp_name = char(inputdlg ('Enter the experiment name (PMI, SMA, etc.) without space')); % user input for the experiment name
%n_data_type=length(dir("data\raw"))-3; % get the number of different data types
%%%n_session=length(dir(tsi_data_path))-2; % get the number of different
%n_data_type = 0;
exp_name = 'PMI';
n_session = 3;

for session = 1:n_session
    data_type_str = 'Localizer';

    %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
    %                               SET PATH
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
    session_str = num2str(session);
    PATHIN_aur  = [aur_data_path '\S' session_str '\']; % emotion regulation % implement looping over sessions
    PATHIN_tsi  = [tsi_data_path '\S' session_str '\']; % emotion regulation % implement looping over sessions

    PATHOUT = [MAINPATH '\post-processed_tsi_data\data\preprocessed\' data_type_str '\S' session_str '\'];

    if ~exist(PATHOUT, 'dir')
        mkdir(PATHOUT)
    end

    %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
    %                           ANALYSIS PIPELINE
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %


    %% decide whether to include QT-NIRS in the pipeline
    % '0' exclude channel removal - sets a very small quality thresholds, 'virtually' excluding QT-NIRS from the pipeline
    % '1' include channel removal - uses standard quality threshold (i.e., 0.6, 0.6, 0.1), performing standard channel quality control

    qtflag=0; % or 1
    subs=dir(PATHIN_aur);
    subs(1:2)=[];
    dum_tsi_data=[];
    dum_scan_quality=[];

    for sub=1:length(subs)
        
        subname=subs(sub).name;
        PATHIN = [PATHIN_aur subname];
        all_files=dir(PATHIN);
        rec_name=all_files(3).name;
        % aurora data
        raw = nirs.io.loadDotNirs([PATHIN '\' rec_name],1);
        % tsi data
        tsisub=dir([PATHIN_tsi '\' subname]);
        load(([PATHIN_tsi '\' subname '\' tsisub(3).name]))

        %This function converts the raw light intensity to optical density and
        %then to Hemoglobin Concentration Changes and devides the
        %timeseries into runs, discrding the pause in between
        [Hb_SDCcor, ScansQuality] = preprocessing_PMI_localizer_offline(raw, qtflag, NFB_Loc);

        %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Save Data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

        %Transform tsi data to nirs type
        [tsi_data] = tsi2nirs_loc_offline(Hb_SDCcor, NFB_Loc);

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

        dum_tsi_data = [dum_tsi_data; tsi_data];
        dum_scan_quality=[dum_scan_quality ScansQuality];
    end

    Hb_SDCcor = dum_tsi_data;
    ScansQuality = dum_scan_quality;

    filename_data = [exp_name '_' data_type_str '_preprocessed.mat'];
    filename_qt = [exp_name '_' data_type_str '_qt_preprocessed.mat']; 

    save([PATHOUT, filename_data], 'Hb_SDCcor');
    save([PATHOUT, filename_qt], 'ScansQuality');

    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

    %     % clean working environment
    close all;
    %   clearvars -except PATHIN PATHOUT data_type data_type_str session exp_name MAINPATH n_data_type n_session
    clc;
    
    %Data standardization

    for ii=1:length(Hb_SDCcor)
        dumdat = Hb_SDCcor(ii);
        dumdat.data = normalize(dumdat.data);
        Hb_SDCcor(ii).data = dumdat.data;
    end   

    %Apply GLM on TSI data
    SubjStats_pruned = GLM_PMI_offline(Hb_SDCcor);

    filename = [PATHOUT exp_name '_' data_type_str '_GLM.mat'];
    save(filename, 'SubjStats_pruned');

    % clean working environment
    close all;
    clearvars -except PATHIN PATHOUT data_type data_type_str session exp_name MAINPATH n_data_type n_session aur_data_path tsi_data_path
    clc;

    % end

end
