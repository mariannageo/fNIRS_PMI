%% NFB SCRIPT FOR POSITIVE MENTAL IMAGERY EXPERIMENT

clear all; close all; clc;
%% NFB SCRIPT: presentation for neurofeedback and processing of real-time data (TSI)
% Created by Franziska Klein a,b,c edited by Marianna Georgiou a, Murat C.
% Mutlu a
% and David Mehler a,b,d
% a Department of Psychiatry, Psychotherapy and Psychosomatics, University Hospital RWTH Aachen, Aachen, Germany
% b Biomedical Devices and Systems Group, R&D Division Health, OFFIS - Institute for Information Technology, Oldenburg, Germany
% c Assistive Systems and Medical Device Technology Group, Department of Health Services Research, University of Oldenburg, Oldenburg, Germany
% d School of Psychology, Cardiff University Brain Research Imaging Center (CUBRIC), Cardiff University, Cardiff, UK


% Using Matlab 2018a

%%%%%%% SET THE FOLLOWING PATHS %%%%%%%%%%%%%%%%%%%%%%%%%%%
STIMULI_PATH   = ''; %'Project\online-scripts-main\Stimuli\';
NFB_PATH       = ''; %'Project\online-scripts-main\NFB\PMI\';  
addpath(genpath('Project\online-scripts-main\TSI_Matlab_Interface\'))  
rt_PATH = ''; %'Project\online-scripts-main\rt\PMI\'; 


%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %%
%                  NEUROFEEDBACK POSITIVE MENTAL IMAGERY                   %
%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %%

% TSI connection
configs.TSI_IP   = 'localhost';
configs.TSI_PORT = 55555;

tsiNetInt = TSINetworkInterface(TSIClient(configs.TSI_IP, configs.TSI_PORT));
tsiNetInt.createConnection();

% LSL Trigger outlet stream
lib    = lsl_loadlib();
info   = lsl_streaminfo(lib, 'Trigger', 'Markers', 1, 0, 'cf_float32', 'Trigger');
outlet = lsl_outlet(info);

    
% Assign keys
KbName('UnifyKeyNames');
enter  = KbName('Return');
escape = KbName('ESCAPE');

%% DAVID: user input - make sure order is the same across scripts to avoid user mistakes!
sex     = input('Female (1) or Male (2)?');
subject = input('Enter subject number: ');
session = input('Enter session number: ');

% ALL CHANNELS, including short short-distance channels! 
% read out from TSI application
all_chans = 1:27; % positive mental imagery: 50, Motor imagery setup: 27 (now in separate script!)
% auto-selected NFB channels
N_CHAN_SEL = 3; 
%% load file with real-time threshold information!
if subject < 10
    NFB_settings_online_filename = ['rt_PMI_NFB_chans', '_s0', num2str(subject), '_session', num2str(session), '_online.mat'];
else
    NFB_settings_online_filename = ['rt_PMI_NFB_chans', '_s', num2str(subject), '_session', num2str(session), '_online.mat'];
end

load([rt_PATH, NFB_settings_online_filename]);

% save also a copy with threshold in NFB folder to allow for easier reproducibility
if subject < 10
    save([NFB_PATH 'rt_NFB_chans', '_s0', num2str(subject), '_session', num2str(session), '_online.mat'], 'NFB_settings_online');
else 
    save([NFB_PATH 'rt_NFB_chans', '_s', num2str(subject), '_session', num2str(session), '_online.mat'], 'NFB_settings_online');
end

% read out threshold
thresh = NFB_settings_online.threshold;

% channel indices for nirs toolbox
% this toolbox has two indices per channel, one index for HbO, one for HbR
% channels_toolbox = NFB_settings.channels;
channels = NFB_settings_online.channels';

% color maps
% warm colors for upregulation (bilateral)
map  = customcolormap([0 0.2 0.4 0.6 0.8 1], {'#db2d59', '#d95351', '#d7794a', '#d59f43', '#d4c63c', '#ffffff'}, 150);

% define timing
numrun      = 3;%supposed to be 3
numTrials   = 8;%supposed to be 8
trialsDur   = 15;  % in s, jittered
restDur_min = 14;  % in s, jittered
restDur_max = 20;  % in s, jittered
longRest    = 20;  % in s, jittered
waitSec_NFB = 2.5; % in s, jittered
calTime     = 30;  %calibration time added to the first and last rest phase of every run to obtain stable filter response
sf          = NFB_settings_online.sf; % sampling frequency
smoothing_time_points = round(sf*2)-1; %number of time points corresponding to 2 seconds over which smoothig in NFB calculation is applied, -1)



% Initialize screen
screen       = Screen('Screens');
screenNumber = max(screen);

% colors
white       = WhiteIndex(screenNumber);
black       = BlackIndex(screenNumber);
grey        = [85, 85, 85];
task_white  = [213, 213, 213];
red         = [237, 134, 131];  % rest background
fr_col      = map(end, :);      % frame
fr_wid      = 8;                % frame width

% open an on screen window
Screen('Preference', 'SkipSyncTests', 1); %!!!!!!!!!!!!!!
% PsychDebugWindowConfiguration(0,0.5);
[mainwin, rect] = PsychImaging('OpenWindow', screenNumber, grey);

%HideCursor;	% Hide the mouse cursor

% get size of the screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', mainwin);

% frame duration
ifi = Screen ('GetFlipInterval', mainwin);

% get centre coordinate of window
[xCenter, yCenter] = RectCenter(rect);

% Set up alpha blending for smooth (anti-aliasing) lines
Screen ('BlendFunction', mainwin, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% load images dependent on gender of the participant
try
    if sex == 1
        imagepath = [STIMULI_PATH, 'Frau_grau.jpg'];
    elseif sex == 2
        imagepath = [STIMULI_PATH, 'Mann_grau.jpg'];
    end
    im_grey     = imread(imagepath);
    imtext_grey = Screen('MakeTexture', mainwin, im_grey);
    [height_head, width_head, ~]   = size(im_grey);
    baseRect_head_grey             = [0 0 width_head height_head];
    
    if sex == 1
        imagepath = [STIMULI_PATH, 'Frau_weiss.jpg'];
    elseif sex == 2
        imagepath = [STIMULI_PATH, 'Mann_weiss.jpg'];
    end
    im_white     = imread(imagepath);
    imtext_white = Screen('MakeTexture', mainwin, im_white);
    [height_head, width_head, ~]   = size(im_white);
    baseRect_head_red              = [0 0 width_head height_head];
catch
    Screen('CloseAll');
    rethrow(lasterror);
end

% POLYGONS
% Number of sides for our polygon
numSides = 6;

% Angles at which our polygon vertices endpoints will be. We start at zero
% and then equally space vertex endpoints around the edge of a circle. The
% polygon is then defined by sequentially joining these end points.
% anglesDeg_right = linspace(0, 360, numSides + 1);
% anglesRad_right = anglesDeg_right * (pi / 180);
% anglesDeg_left  = linspace(0, -360, numSides + 1);
% anglesRad_left  = anglesDeg_left * (pi / 180);

anglesDeg_right = linspace(0, 360, numSides + 1)+30; % ADDED by MURAT on 20.03.25
anglesDeg_right = mod(anglesDeg_right,360); % ADDED by MURAT on 20.03.25
anglesRad_right = anglesDeg_right * (pi / 180); 
anglesDeg_left  = linspace(0, -360, numSides + 1)+30; % ADDED by MURAT on 20.03.25
anglesDeg_left = mod(anglesDeg_left,360); % ADDED by MURAT on 20.03.25
anglesRad_left  = anglesDeg_left * (pi / 180); 
anglesDeg_mid  = linspace(0, 360, numSides + 1)+30; % ADDED by MURAT on 20.03.25
anglesDeg_mid = mod(anglesDeg_mid,360); % ADDED by MURAT on 20.03.25
anglesRad_mid  = anglesDeg_mid * (pi / 180); % ADDED by MURAT on 20.03.25
radius          = 75;

% X and Y coordinates of the points defining out polygon, centred at the
% centre of the screen
yPosVector_right = sin(anglesRad_right) .* radius + yCenter;
xPosVector_right = cos(anglesRad_right) .* radius + xCenter;

yPosVector_left  = sin(anglesRad_left) .* radius + yCenter;
xPosVector_left  = cos(anglesRad_left) .* radius + xCenter;
isConvex         = 1;

yPosVector_mid  = sin(anglesRad_mid) .* radius + yCenter; % ADDED by MURAT on 20.03.25
xPosVector_mid  = cos(anglesRad_mid) .* radius + xCenter; % ADDED by MURAT on 20.03.25


% ~~~~~~~~~~~~~~~~~~~~ %
%%  start experiment
% ~~~~~~~~~~~~~~~~~~~~ %
rest_phaseAll = 0;
task_all      = 0;
tmp_all_runs  = [];
try
    % run
    for run = 1:numrun
        restPhase = 0;
        
        if run == 1
            % start screen
            outlet.push_sample(7);
            Screen('FillRect', mainwin, grey);
            Screen('TextSize', mainwin, 60);
            DrawFormattedText( mainwin, 'It is starting soon. Press ENTER to continue...', 'center', 'center', task_white);
            Screen('Flip',     mainwin);
            buttonPress(mainwin, enter, escape);
        end
        
        for trial = 1:numTrials % loop over trials
            
            if trial == 1
                
                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
                %% Rest phase without NFB
                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
                outlet.push_sample(1);
                restPhase                   = restPhase + 1;
                rest_phaseAll               = rest_phaseAll + 1;
                firstRestDur = longRest + calTime;
                restDur_Vec(run, restPhase) = firstRestDur; % first rest phase is max length
                
                try
                    tPoint     = 0;
                    t02        = clock;
                    count_Rest = 0;
                    while etime(clock, t02) < firstRestDur
                        try
                            tPoint = tPoint + 1;
                            % get current time point from TSI
                            tmp_rest(rest_phaseAll, tPoint) = double(tsiNetInt.tGetCurrentTimePoint());
                            
                            if tPoint > 1 && tmp_rest(rest_phaseAll, tPoint) > max(tmp_rest(rest_phaseAll, 1:tPoint-1))
                                count_Rest = count_Rest + 1;
                                cur_tp_rest(rest_phaseAll, count_Rest) = tmp_rest(rest_phaseAll, tPoint);
                                
                                % no BL correction here because the first
                                % Rest period is always without any NFB
                                data                       = tsiNetInt.tGetDataDeOxy(channels, cur_tp_rest(rest_phaseAll, count_Rest)-1);
                                allDat_Rest(:, count_Rest) = double(data);
                                
                                %% VISUALISATION REST IN GREY WITHOUT NFB
                                % one trial
                                Screen('FillRect',    mainwin, grey);
                                Screen('DrawTexture', mainwin, imtext_grey);
                                Screen('Flip',        mainwin);
                                
                            else
                                continue;
                            end
                        catch R1
                            continue;
                        end
                    end
                catch R2
                end
                deoxyDat_Rest{rest_phaseAll} = allDat_Rest;
                  
                % compute baseline for feedback phase:
                % skipping first 6 seconds of rest for BL computation
                % (could be some task activity going on from previous task
                % period)
                bl_keep = 3; % was "bl_skip= 6;" before. Changed to keep the last 3 seconds of the rest period
                dp_BL_start = round(bl_keep * sf);
                
                rest_data_skipped = allDat_Rest(:, (end-dp_BL_start):end);
                prev_BL = nanmedian(rest_data_skipped, 2);
                
            end
            
            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
            %% neurofeedback phase
            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
            try
                % send trigger
                
                outlet.push_sample(2);
                
                tPoint   = 0;
                t02      = clock;
                count    = 0;
                allDat   = [];
                task_all = task_all + 1;
                
                % save BL-corrected DeOxy TSI-processed channel data during experiment for the sliding window
                % median is then computed over this vector (mean for first
                % 20 time steps of trial)
                % this vector is filled timepoint-by-timepoint
                % it is filled with last-in-first-out (lifo) principle
                % in the beginning of a trial, the first entries are
                % equal to the last time points of the preceding rest phase
                % row ~ timepoint, column ~ channel
                windowData = deoxyDat_Rest{rest_phaseAll}(:, end - smoothing_time_points:end)';
                
                while etime(clock, t02) < trialsDur
                    try
                        tPoint             = tPoint + 1;
                        tmp(trial, tPoint) = double(tsiNetInt.tGetCurrentTimePoint());
                        
                        if tPoint > 1 && tmp(trial, tPoint) > max(tmp(trial, 1:tPoint-1))
                            count = count + 1;
                            cur_tp(trial, count) = tmp(trial, tPoint);
                            
                            data             = tsiNetInt.tGetDataDeOxy(channels, cur_tp(trial, count)-1);
                            allDat(:, count) = double(data);
                            deoxyDat_BL      = double(data) - prev_BL'; % BL corrected data
                            
                            % last in
                            windowData(end+1,:) = deoxyDat_BL;
                            % first out
                            windowData          = windowData(2:end,:);
                            
                            % median per channel over last 10 time-points
                            deoxyDat_BL_smoothed = median(windowData,1);
                           
                            % generate color for NFB
                            FBcolor = colorsForNFB_deoxy(deoxyDat_BL_smoothed, map, thresh);
                            NFBcolors(:,:,count,task_all)=FBcolor; 

                            %% VISUALISATION OF NFB
                            % one trial
                            Screen('FillRect',    mainwin, task_white);
                            Screen('DrawTexture', mainwin, imtext_white);
                            framCol  = fr_col*255;
                            
                            % Draw the rect to the screen
                            if count <= round(waitSec_NFB*sf)
                                % wait first few seconds at beginning of run (first trial)
                                Screen('TextSize', mainwin, 20);
                               NFB_viz_BA9(xPosVector_mid, yPosVector_mid, xPosVector_left, yPosVector_left, xPosVector_right, yPosVector_right, isConvex, ...
                                    fr_wid, [], mainwin, framCol, 1); 
                                Screen('Flip', mainwin);
                            else
                                Screen('TextSize', mainwin, 20);
                                NFB_viz_BA9(xPosVector_mid, yPosVector_mid, xPosVector_left, yPosVector_left, xPosVector_right, yPosVector_right, isConvex, ...
                                    fr_wid, FBcolor, mainwin, framCol, 0);
                                Screen('Flip', mainwin);
                                
%                                 im = Screen('GetImage', mainwin);
%                                 imwrite(im, ['C:\Users\User\Documents\Projects\fNIRS_feasibility\Design\feedback_visualization\count_' num2str(count) '.jpg']);
                            end
                            
                        else
                            continue;
                        end
                    catch NFB1
                        continue;
                    end
                end
            catch NFB2
            end
            deoxyDat{task_all} = allDat;
            
            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
            %% Rest phase
            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
            % send trigger
            outlet.push_sample(1);
            
            rest_phaseAll = rest_phaseAll + 1;
            restPhase     = restPhase + 1;
            
            % select rest period (pseudo-) randomly
            restDur                     = round((restDur_max - restDur_min).*rand(1) + restDur_min); 

            if trial == numTrials % Check if it's the last trial and add 30 seconds to rest duration
                restDur = restDur + calTime;
            end
            
            restDur_Vec(run, restPhase) = restDur;
            try
                tPoint      = 0;
                t02         = clock;
                count_Rest  = 0;
                allDat_Rest = [];
                while etime(clock, t02) < restDur
                    try
                        tPoint = tPoint + 1;
                        tmp_rest(rest_phaseAll, tPoint) = double(tsiNetInt.tGetCurrentTimePoint());
                        
                        if tPoint > 1 && tmp_rest(rest_phaseAll, tPoint) > max(tmp_rest(rest_phaseAll, 1:tPoint-1))
                            
                            count_Rest = count_Rest + 1;
                            cur_tp_rest(rest_phaseAll, count_Rest) = tmp_rest(rest_phaseAll, tPoint);
                            
                            data = tsiNetInt.tGetDataDeOxy(channels, cur_tp_rest(rest_phaseAll, count_Rest)-1);
                            allDat_Rest(:, count_Rest) = double(data);
                            
                            %% VISUALISATION REST IN WHITE WITHOUT NFB
                            % one trial
                            Screen('FillRect',    mainwin, grey);
                            Screen('DrawTexture', mainwin, imtext_grey);
                            Screen('Flip',        mainwin);
                            
                        else
                            continue;
                        end
                    catch R4
                        continue;
                    end
                end
            catch R6
                continue;
            end
            deoxyDat_Rest{rest_phaseAll} = allDat_Rest;
            
            % compute baseline for feedback phase:                
            % skipping first 6 seconds of rest for BL computation
            % (could be some task activity going on from previous task
            % period)
            bl_keep     = 3; % was bl_skip = 6; before. Changed to keep the last 3 seconds of the rest.
            dp_BL_start = round(bl_keep * sf);
            
            rest_data_skipped = allDat_Rest(:, (end-dp_BL_start):end);
            prev_BL = nanmedian(rest_data_skipped, 2);
            
        end
        
        if size(tmp_all_runs, 2) > size(tmp,2)
            size_diff = size(tmp_all_runs, 2) - size(tmp,2);
            padded = [tmp zeros(size(tmp,1), size_diff)];
            tmp_all_runs = [tmp_all_runs; padded];
        elseif size(tmp_all_runs, 2) < size(tmp,2)
            size_diff = size(tmp,2) - size(tmp_all_runs, 2);
            padded = [tmp_all_runs zeros(size(tmp_all_runs,1), size_diff)];
            tmp_all_runs = [padded; tmp];
        else
            tmp_all_runs = [tmp_all_runs; tmp];
        end
        
        clear tmp

        % present short break between two runs
        if run ~= numrun
            % break
            outlet.push_sample(5);
            
            Screen('FillRect', mainwin, grey);
            Screen('TextSize', mainwin, 50);
            DrawFormattedText( mainwin, ['Short break. \n \n', ...
                'Please move as little as possible, \n', ...
                'only when it is necessary, for the rest of \n', ...
                'the experiment. \n \n', ...
                'Please inform the experimenter, \n', ...
                'when you are ready to resume the session.' ], 'center', 'center' , task_white );
            Screen('Flip',     mainwin); %flip for the stimulus to show up on the mainwin
            buttonPress(mainwin, enter, escape);
        end
    end
    % end screen
    outlet.push_sample(7);
    
    Screen('FillRect', mainwin, grey);
    Screen('TextSize', mainwin, 50);
    DrawFormattedText( mainwin, ['The experiment is over! Thank you for your participation. \n \n', ...
        'Please move as little as possible \n', ...
        'until further notice.'], 'center', 'center' , task_white );
    Screen('Flip',     mainwin); %flip for the stimulus to show up on the mainwin
    
catch  EXP
    Screen('CloseAll');
    rethrow(lasterror);
    
end
KbStrokeWait;
sca;
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%%              READ-OUT REAL-TIME PROCESSED TSI DATA
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% we will read out this data now for all channels
clearvars deoxyDat_Rest deoxyDat

% we could not read out this data in the code above during the experiment
% because the data was not read out correctly (many zeros)

% all TSI-timepoints are saved in tmp_rest (rest) and tmp (task)
% we can use these timepoints to read-out, now after the experiment, the
% rt-processed data (i.e. HbO / HbR after TSI did some online real-time
% processing)

% run through all rest phases (one more than NFB phases, i.e. one more than #trials):
for i = 1:size(tmp_rest,1)
    
    trialDat_Rest_oxy   = [];
    trialDat_Rest_deoxy = [];
    
    % read out time points for i-th rest phase
    curr_rest_tpoints = tmp_rest(i, :);
    
    % time points are repeated due to internal processing
    % but we want to look at each time point once
    curr_rest_tpoints = nonzeros(unique(curr_rest_tpoints))';
    
    % run through all time points to read-out data
    for t = 1:length(curr_rest_tpoints)
        
        % read out data from TSI with time-point t, which is within the
        % i-th rest phase
        t_data_oxy   = tsiNetInt.tGetDataOxy(all_chans, curr_rest_tpoints(t))';
        t_data_deoxy = tsiNetInt.tGetDataDeOxy(all_chans, curr_rest_tpoints(t))';
        
        % save all data for oxy/deoxy of i-th rest phase
        trialDat_Rest_oxy(:, t)   = t_data_oxy;
        trialDat_Rest_deoxy(:, t) = t_data_deoxy;
    end
    
    % save data of all trials here
    oxyDat_Rest{i}   = trialDat_Rest_oxy;
    deoxyDat_Rest{i} = trialDat_Rest_deoxy;
end

% run through all task phases:
for i = 1:size(tmp_all_runs,1)
    
    trialDat_oxy = [];
    trialDat_deoxy = [];
    
    % read out time points for i-th task phase
    curr_task_tpoints = tmp_all_runs(i,:);
    
    % time points are repeated due to internal processing
    % but we want to look at each time point once
    curr_task_tpoints = nonzeros(unique(curr_task_tpoints))';
    
    % run through all time points to read-out data
    for t = 1:length(curr_task_tpoints)
        
        % read out data from TSI with time-point t, which is within the
        % i-th task phase
        t_data_oxy   = tsiNetInt.tGetDataOxy(all_chans, curr_task_tpoints(t))';
        t_data_deoxy = tsiNetInt.tGetDataDeOxy(all_chans, curr_task_tpoints(t))';
        
        % save all data for oxy/deoxy of i-th rest phase
        trialDat_oxy(:, t)   = t_data_oxy;
        trialDat_deoxy(:, t) = t_data_deoxy;
    end
    
    % save data of all trials here
    oxyDat{i}   = trialDat_oxy;
    deoxyDat{i} = trialDat_deoxy;
end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%%                         SAVE RESULTS
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %

% to get only the data which was used for NFB in trial i:
% NFB_data = deoxyDat{1,i}(channels,:);
% channels is the variable w

deoxyNFB_NFBdat.NFB_dat_deoxy  = deoxyDat;
deoxyNFB_NFBdat.Rest_dat_deoxy = deoxyDat_Rest;
deoxyNFB_NFBdat.rest_durations = restDur_Vec;
deoxyNFB_NFBdat.NFB_chans      = channels;
deoxyNFB_NFBdat.NFB_colors      = NFBcolors; % ADDED BY MURAT on 06.01.25

oxyNFB_NFBdat.NFB_dat_oxy    = oxyDat;
oxyNFB_NFBdat.Rest_dat_oxy   = oxyDat_Rest;
oxyNFB_NFBdat.rest_durations = restDur_Vec;
oxyNFB_NFBdat.NFB_chans      = channels;

if subject < 10
    save([NFB_PATH, 'PMI_deoxyNFB_s0',  num2str(subject), '_session_', num2str(session), '.mat'], 'deoxyNFB_NFBdat');
else
    save([NFB_PATH, 'PMI_deoxyNFB_s',   num2str(subject), '_session_', num2str(session), '.mat'], 'deoxyNFB_NFBdat');
end

if subject < 10
    save([NFB_PATH, 'PMI_oxyNFB_s0',  num2str(subject), '_session_', num2str(session), '.mat'], 'oxyNFB_NFBdat');
else
    save([NFB_PATH, 'PMI_oxyNFB_s',   num2str(subject), '_session_', num2str(session), '.mat'], 'oxyNFB_NFBdat');
end