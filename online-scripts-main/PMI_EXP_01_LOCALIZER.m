%% LOCALIZER SCRIPT FOR POSITIVE MENTAL IMAGERY EXPERIMENT

clear all; close all; clc;
%% LOCALIZER SCRIPT: presentation for localizer and processing of real-time data (TSI) for later threshold caculation
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
LOCALIZER_PATH = '';%'Project\online-scripts-main\LOCALIZER\PMI\';  
addpath(genpath('Project\online-scripts-main\TSI_Matlab_Interface\'))  
rt_PATH = ''; %'Project\online-scripts-main\rt\PMI\'; 

%In the end of the experiment the TSI online processed data are saved in
%two different copies, one in LOCALIZER_PATH, and one in rt_PATH
%the copy from the rt_PATH will be transfered via cable or online to the
%other laptop A where will be processed from the PMI_EXP_02_NFB_PREPARATION.m script

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %%
%                     LOCALIZER POSITIVE MENTAL IMAGERY                   %
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

% user input
sex     = input('Female (1)  Male (2)?'); 
session = input('Enter session number: ');
subject = input('Enter subject number: ');

% ALL CHANNELS, including short short-distance channels! 
% read out from TSI application
all_chans = 1:27; 

% define timing
numrun      = 2;   % number of runs
numTrials   = 7;   % number of trials/run
trialsDur   = 15;  % trial duration (in s)
restDur_min = 14;  % rest duration (s), jittered
restDur_max = 20;  % rest duration (s), jittered 
longRest    = 20;  % rest duration (s)
calTime = 30; %callibration time added to the first and last rest phase of every run

% Initialize screen
screen       = Screen('Screens');
screenNumber = max(screen);

% colors
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey  = [85, 85, 85];
task_white = [213, 213, 213];
red   = [237, 134, 131];

% open an on screen window
Screen('Preference', 'SkipSyncTests', 1); %!!!!!!!!!!!!!!
%PsychDebugWindowConfiguration(0,0.5);
[mainwin, rect] = PsychImaging('OpenWindow', screenNumber, grey);

HideCursor;	% Hide the mouse cursor    

% get size of the screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', mainwin);

% frame duration
ifi = Screen ('GetFlipInterval', mainwin);

% get centre coordinate of window
[xCenter, yCenter] = RectCenter(rect);

% Set up alpha blending for smooth (anti-aliasing) lines             
Screen ('BlendFunction', mainwin, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% load top-view head images dependent on gender of the participant
try
    if sex == 1
        imagepath = [STIMULI_PATH, 'Frau_grau.jpg'];
    elseif sex == 2
        imagepath = [STIMULI_PATH, 'Mann_grau.jpg'];
    end
    im_grey = imread(imagepath);
    imtext_grey = Screen('MakeTexture', mainwin, im_grey);
    [height_head, width_head, ~] = size(im_grey);
    baseRect_head_grey = [0 0 width_head height_head];
    
    if sex == 1
        imagepath = [STIMULI_PATH, 'Frau_weiss.jpg'];
    elseif sex == 2
        imagepath = [STIMULI_PATH, 'Mann_weiss.jpg'];
    end
    im_white = imread(imagepath);
    imtext_white = Screen('MakeTexture', mainwin, im_white);
    [height_head, width_head, ~] = size(im_white);
    baseRect_head_red = [0 0 width_head height_head];
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
anglesDeg_right = linspace(0, 360, numSides + 1);
anglesRad_right = anglesDeg_right * (pi / 180);
anglesDeg_left  = linspace(0, -360, numSides + 1);
anglesRad_left  = anglesDeg_left * (pi / 180);
radius          = 60;

% X and Y coordinates of the points defining out polygon, centred at the
% centre of the screen
yPosVector_right = sin(anglesRad_right) .* radius + yCenter;
xPosVector_right = cos(anglesRad_right) .* radius + xCenter;

yPosVector_left  = sin(anglesRad_left) .* radius + yCenter;
xPosVector_left  = cos(anglesRad_left) .* radius + xCenter;
isConvex         = 1;

check_tp_rest = [];
check_block = [];

% ~~~~~~~~~~~~~~~~~~~~ %
%%  start experiment
% ~~~~~~~~~~~~~~~~~~~~ %
try 
    % loop over runs
    for run = 1:numrun
        rest_phase = 0;
        
        if run == 1
            % start screen
            outlet.push_sample(7);
            Screen('FillRect', mainwin, grey);
            Screen('TextSize', mainwin, 60);
            DrawFormattedText( mainwin, 'It is starting soon. Press ENTER to continue...', 'center', 'center', task_white);
            Screen('Flip',     mainwin);
            buttonPress(       mainwin, enter, escape);
        end

        
        % loop over trials
        for trial = 1:numTrials 
            
            if trial == 1 

                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
                %% Rest phase without NFB
                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
                
                % first rest phase max of rest phases
                outlet.push_sample(1);
                rest_phase = rest_phase + 1;
                firstRestDur = longRest + calTime; 

                restDur_vec(run, rest_phase) = firstRestDur;

                try
                    tPoint     = 0;
                    t02        = clock;
                    while etime(clock, t02) < firstRestDur
                        try 
                            tPoint = tPoint + 1;
                            % get current time point from TSI
                            tmp_rest(run, rest_phase, tPoint) = double(tsiNetInt.tGetCurrentTimePoint());

                            if tPoint > 1 && tmp_rest(run, rest_phase, tPoint) > max(tmp_rest(run, rest_phase, 1:tPoint-1))

                                %% VISUALISATION REST WITH GREY BACKGROUND
                                %  AND WITHOUT NFB
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
            end

            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
            %% neurofeedback phase
            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
            try
                % send trigger
                outlet.push_sample(2);
    
                tPoint = 0;
                t02    = clock;
                allDat = [];
                while etime(clock, t02) < trialsDur
                    try 
                	    tPoint = tPoint + 1;
                        tmp(run, trial, tPoint) = double(tsiNetInt.tGetCurrentTimePoint());
    
                        if tPoint > 1 && tmp(run, trial, tPoint) > max(tmp(run, trial, 1:tPoint-1))
                            
                            %% VISUALISATION TASK WITH WHITE BACCKGROUND
                            %  and without NFB
                            Screen('FillRect',    mainwin, task_white);
                            Screen('DrawTexture', mainwin, imtext_white); 
                            Screen('Flip',        mainwin);

                        else
                            continue;
                        end
                    catch NFB1
                        continue;
                    end
                end
            catch NFB2
            end 

            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
            %% Rest phase
            %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
            % send trigger
            outlet.push_sample(1);
            
            rest_phase = rest_phase + 1; 
            clearvars dataChunks
            restDur                      = round((restDur_max - restDur_min).*rand(1) + restDur_min); % select baseline period (pseudo-) randomly
            
            if trial == numTrials % Check if it's the last trial and add 30 seconds to rest duration
                restDur = restDur + calTime;
            end
            
            restDur_vec(run, rest_phase) = restDur;
            
            try
                tPoint      = 0;
                t02         = clock;
                while etime(clock, t02) < restDur
                    try 
                        tPoint = tPoint + 1;
                        tmp_rest(run, rest_phase, tPoint) = double(tsiNetInt.tGetCurrentTimePoint());

                        if tPoint > 1 && tmp_rest(run, rest_phase, tPoint) > max(tmp_rest(run, rest_phase, 1:tPoint-1))
                            
                            %% VISUALISATION REST IN GREY 
                            % one trial 
                            Screen('FillRect',    mainwin, grey);
                            Screen('DrawTexture', mainwin, imtext_grey); 
                            Screen('Flip',        mainwin); %flip for the stimulus to show up on the mainwin
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
        end

            
        
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

    outlet.push_sample(7);
    
    Screen('FillRect', mainwin, grey);
    Screen('TextSize', mainwin, 50);
    DrawFormattedText( mainwin, ['The first part of the measurement is over. Thank you for your participation. \n \n', ...
        'Please move as little as possible, \n', ...
        'until further notice.'], 'center', 'center' , task_white );
    Screen('Flip',     mainwin); %flip for the stimulus to show up on the mainwin

catch EXP    
    Screen('CloseAll');
    rethrow(lasterror);
end  
KbStrokeWait;
sca;

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%%              READ-OUT REAL-TIME PROCESSED TSI DATA
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% we could not read out oxy data in the code above during the experiment
% because the data was not read out correctly (many zeros)

% all TSI-timepoints are saved in temp (rest) and tmp (task)
% we can use these timepoints to read-out, now after the experiment, the
% rt-processed data (i.e. HbO / HbR after TSI did some online real-time
% processing)

% run through all rest phases (one more than NFB phases, i.e. one more than #trials):
for r = 1:numrun % loop over all runs
    for t = 1:size(tmp_rest, 2) % trials
        
        trialDat_Rest_deoxy = [];
        trialDat_Rest_oxy   = [];
        
        trialDat_Rest_wl1 = [];
        trialDat_Rest_wl2 = [];
        
        % read out time points for i-th rest phase
        curr_rest_tpoints = squeeze(tmp_rest(r, t, :));
        
        % time points are repeated due to internal processing
        % but we want to look at each time point once
        curr_rest_tpoints = nonzeros(unique(curr_rest_tpoints))';
        
        % run through all time points to read-out data
        for tp = 1:length(curr_rest_tpoints)
     
            % read out data from TSI with time-point t, which is within the
            % i-th rest phase
            t_data_deoxy = tsiNetInt.tGetDataDeOxy(all_chans, curr_rest_tpoints(tp))';
            t_data_oxy   = tsiNetInt.tGetDataOxy(all_chans, curr_rest_tpoints(tp))';
            
            % read out the raw light intensities 
            t_data_wl1 = tsiNetInt.tGetRawDataWL1(all_chans, curr_rest_tpoints(tp))';
            t_data_wl2 = tsiNetInt.tGetRawDataWL2(all_chans, curr_rest_tpoints(tp))';

           
            
            % save all data for oxy/deoxy of i-th rest phase
            trialDat_Rest_deoxy(tp, :) = t_data_deoxy;
            trialDat_Rest_oxy(tp, :)   = t_data_oxy;
            
            % save all data for oxy/deoxy of i-th rest phase - ADDED BY MURAT ON
            % 25.11.24
            trialDat_Rest_wl1(tp, :) = t_data_wl1;
            trialDat_Rest_wl2(tp, :) = t_data_wl2;
            
        end

        % save data of all trials here
        Dat_Rest_deoxy{r, t} = trialDat_Rest_deoxy;
        Dat_Rest_oxy{r, t}   = trialDat_Rest_oxy;
        
        % save data of all trials here
        Dat_Rest_wl1{r, t} = trialDat_Rest_wl1;
        Dat_Rest_wl2{r, t} = trialDat_Rest_wl2;
        
        
    end
end

% run through all task phases:
for r = 1:numrun % runs
    for t = 1:size(tmp, 2) % trials
        
        trialDat_deoxy = [];
        trialDat_oxy   = [];
        
        trialDat_wl1 = [];
        trialDat_wl2 = [];
        
        % read out time points for i-th task phase
        curr_task_tpoints = squeeze(tmp(r, t, :));
        
        % time points are repeated due to internal processing
        % but we want to look at each time point once
        curr_task_tpoints = nonzeros(unique(curr_task_tpoints))';
        
        % run through all time points to read-out data
        for tp = 1:length(curr_task_tpoints)
     
            % read out data from TSI with time-point t, which is within the
            % i-th task phase
            t_data_deoxy = tsiNetInt.tGetDataDeOxy(all_chans, curr_task_tpoints(tp))';
            t_data_oxy   = tsiNetInt.tGetDataOxy(all_chans, curr_task_tpoints(tp))';
            
            t_data_wl1 = tsiNetInt.tGetRawDataWL1(all_chans, curr_task_tpoints(tp))';
            t_data_wl2 = tsiNetInt.tGetRawDataWL2(all_chans, curr_task_tpoints(tp))';
       
            % save all data for oxy/deoxy of i-th rest phase
            trialDat_deoxy(tp, :) = t_data_deoxy;
            trialDat_oxy(tp, :)   = t_data_oxy;
            
            trialDat_wl1(tp, :) = t_data_wl1;
            trialDat_wl2(tp, :) = t_data_wl2;
        end
        % save data of all trials here
        Dat_deoxy{r, t} = trialDat_deoxy;
        Dat_oxy{r, t}   = trialDat_oxy;
        
        Dat_wl1{r, t} = trialDat_wl1;
        Dat_wl2{r, t} = trialDat_wl2;
        
        
    end
end

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%%                          SAVE DATA
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% NFB_Loc.raw_data = raw_data; % ??
NFB_Loc.NFB_dat_deoxy  = Dat_deoxy;
NFB_Loc.Rest_dat_deoxy = Dat_Rest_deoxy;
NFB_Loc.NFB_dat_oxy    = Dat_oxy;
NFB_Loc.Rest_dat_oxy   = Dat_Rest_oxy;
NFB_Loc.rest_durations = restDur_vec;

NFB_Loc.NFB_dat_wl1  = Dat_wl1;
NFB_Loc.Rest_dat_wl1 = Dat_Rest_wl1;
NFB_Loc.NFB_dat_wl2  = Dat_wl2;
NFB_Loc.Rest_dat_wl2 = Dat_Rest_wl2;


% save localizer data
if subject < 10
    save([LOCALIZER_PATH, 'PMI_NFB_LOCALIZER_s0',  num2str(subject), '_session_', num2str(session), '.mat'], 'NFB_Loc');   
else
    save([LOCALIZER_PATH, 'PMI_NFB_LOCALIZER_s',   num2str(subject), '_session_', num2str(session), '.mat'], 'NFB_Loc');   
end

% save also a copy in rt folder for transfer to the other laptop
if subject < 10
    save([rt_PATH, 'PMI_NFB_LOCALIZER_s0',  num2str(subject), '_session_', num2str(session), '.mat'], 'NFB_Loc');   
else
    save([rt_PATH, 'PMI_NFB_LOCALIZER_s',   num2str(subject), '_session_', num2str(session), '.mat'], 'NFB_Loc');   
end