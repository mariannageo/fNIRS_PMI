% This script is used for training purposes. It performs one run (see numRun)
% and seven trials (see numTrials) of the upcoming measurement, without
% providing neurofeedback (NFB) and without saving the TSI data. However,
% raw data are saved automatically by Aurora.

% Using Matlab 2021b

clear all; close all; clc;

STIMULI_PATH   = 'C:\Users\User\Documents\Projects\fNIRS_feasibility\Code\Stimuli\';    %define yours
addpath(genpath('C:\Users\User\Documents\Projects\fNIRS_feasibility\Code\TSI_Matlab_Interface\')) %define yours

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

sex     = input('Female (1) or Male (2)?'); 
subject = input('Enter subject number: ');
session = input('Enter session number: ');

% define experiment parameters
numrun      = 1; %number of runs
numTrials   = 7;  %number of trials
trialsDur   = 15;  % s %task duration
restDur_min = 14;  % s, min rest duration
restDur_max = 20;  % s, max rest duration 
longRest    = 20;  % s


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
        
        % start screen
        outlet.push_sample(7);
        Screen('FillRect', mainwin, grey);
        Screen('TextSize', mainwin, 60);
        DrawFormattedText( mainwin, 'It is starting soon. Press ENTER to continue...', 'center', 'center', task_white);
        Screen('Flip',     mainwin);
        buttonPress(       mainwin, enter, escape);
        
        % loop over trials
        for trial = 1:numTrials 
            
            if trial == 1 

                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
                %% Rest phase without NFB
                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
                
                % first rest phase max of rest phases
                outlet.push_sample(1);
                rest_phase = rest_phase + 1;
                restDur_vec(run, rest_phase) = longRest;

                try
                    tPoint     = 0;
                    t02        = clock;
                    count_Rest = 0;
                    while etime(clock, t02) < longRest
                        try 
                            tPoint = tPoint + 1;
                            % get current time point from TSI
                            tmp_rest(rest_phase, tPoint) = double(tsiNetInt.tGetCurrentTimePoint());

                            if tPoint > 1 && tmp_rest(rest_phase, tPoint) > max(tmp_rest(rest_phase, 1:tPoint-1))
                                count_Rest = count_Rest + 1;

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
                count  = 0;
                allDat = [];
                while etime(clock, t02) < trialsDur
                    try 
                	    tPoint = tPoint + 1;
                        tmp(trial, tPoint) = double(tsiNetInt.tGetCurrentTimePoint());
    
                        if tPoint > 1 && tmp(trial, tPoint) > max(tmp(trial, 1:tPoint-1))
                            count = count + 1;
                            
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
            restDur_vec(run, rest_phase) = restDur;
            try
                tPoint      = 0;
                t02         = clock;
                count_Rest  = 0;
                allDat_Rest = [];
                while etime(clock, t02) < restDur
                    try 
                        tPoint = tPoint + 1;
                        tmp_rest(rest_phase, tPoint) = double(tsiNetInt.tGetCurrentTimePoint());

                        if tPoint > 1 && tmp_rest(rest_phase, tPoint) > max(tmp_rest(rest_phase, 1:tPoint-1))
                            count_Rest = count_Rest + 1;
                            
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
    end
    % end screen
    outlet.push_sample(7);
    
    Screen('FillRect', mainwin, grey);
    Screen('TextSize', mainwin, 50);
    DrawFormattedText( mainwin, ['The training is over! \n \n', ...
        'Please inform the experimenter.'], 'center', 'center' , task_white);
    Screen('Flip',     mainwin); %flip for the stimulus to show up on the mainwin

catch EXP    
    Screen('CloseAll');
    rethrow(lasterror);
end  
KbStrokeWait;
sca;