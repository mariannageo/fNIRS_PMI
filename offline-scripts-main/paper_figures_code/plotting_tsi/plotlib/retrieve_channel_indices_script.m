%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%% Retrieve relevant channel indices script v1 - by David and Marianna (17.05.2024)

%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
close all; clear all; clc;
addpath([pwd '\helper'])
%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                           SELECT MONTAGE
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% montage types:
% choose 0 for PMI 16x16 montage
% choose 1 for PMI 8x8 montage [coding in progress]
% choose 2 for Motor imagery (SMA) 8x8 setup [still needs to be coded]
montage = 2;
%% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%                               SET PATHES
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
%% NEEDS TO BE CHANGED; DEPENDS ON DATA BATCH THAT IS ANALYSED
task_type_str = 'motor_pilot_latest\ME_LOC'; % 'emotion_regulation'; %'emotion_regulation'; %motor_imagery
MAINPATH = ['C:\projects\fNIRS\' task_type_str '\'];
BATCHPATH_STR = 'piloting'; %'piloting_cntbckwrds_0124'; % string part that identifies data batch that is being analysed
%% GENERIC PART
PATHPLOTS = pwd;
cd ..; cd ..;
%MAINPATH = [pwd '\'];
% iloting_cntbckwrds_8x8
%[pwd '\'];
cd(PATHPLOTS);
PATHIN = [MAINPATH 'data\preprocessed_' BATCHPATH_STR '\S1\'];
%% LOAD DATA
filename_data = 'PMI_localizer_GLM.mat';
load([PATHIN, filename_data], 'SubjStats_pruned');
%% montage layout source-detector combinations
% NOTE: sources and dector combination in the order as channels are listed in
% createfigure_Map_xxx.m file for the respective montage!!
if montage == 0 % for PMI 16x16 setup
    sources_enum = [10, 2, 9, 9, 9, 10, 14, 12, 1, 1, 1, 4, 2, 2,  ... % same order as in createfigure_Map_PMI_16x16.m
        4, 4, 4, 11, 11]; 

    detector_enum = [7, 3, 5, 7, 6, 8, 8, 8, 5, 6, 1, 4, 5, 7, ...
        3, 2, 1, 6, 8]; 

elseif montage == 1 % PMI 8x8
    sources_enum = [7, 3, 5, 5, 5, 2, 2, 2, 3, 3, 1, 1, 6]; % same order as in createfigure_Map_PMI_8x8.m

    detector_enum = [6, 3, 2, 6, 5, 2, 5, 1, 2, 6, 3, 1, 5]; 

elseif montage == 2 % Motor Imagery SMA 8x8 - read off from montage image file
    sources_enum = [1, 1, 2, ... % 1st row
        3, 1, 4, 2, ... % 2nd row
        3, 3, 4, 4, 5, ... % 3rd row
        3, 6, 4, 7, ... % 4th row
        6, 6, 7]; % 5th row

    detector_enum = [1, 2, 2, ... 
        1, 4, 2, 5, ... 
        3, 4, 4, 5, 5, ... 
        6, 4, 7, 5, ...
        6, 7, 7];
end
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ %
% note: it does not matter if this is computed for hbo or hbr as we refer to the
% index of index
COND = 'PMI:01'; % task marker is the same for all montages
sub_group_idx_hbr = [];
for chan = 1:length(sources_enum)
    chan_idx_hbo = find(SubjStats_pruned(1,1).probe.link.source==sources_enum(chan) & SubjStats_pruned(1,1).probe.link.detector==detector_enum(chan) & ...
    SubjStats_pruned(1,1).probe.link.ShortSeperation==0 & strcmp(SubjStats_pruned(1,1).probe.link.type, 'hbr'));
    sub_group_idx_hbr = [sub_group_idx_hbr; chan_idx_hbo]; % HbR
end

% index with all channels to find then the position of the channels of interest (i.e., determine the index of index) 
all_idx_hbr = find(strcmp(SubjStats_pruned(1, 1).variables.type, 'hbr') & ...
            strcmp(SubjStats_pruned(1, 1).variables.cond, COND) & ...
            ismember(SubjStats_pruned(1, 1).variables.ShortSeperation, 0));

pos_idx_hbr=[]; % returns index of index, based on the order as provided above in the montage layout 
for i=1:length(sub_group_idx_hbr) % (for PMI: order identical with order in createfigure_Map_PMI_xxx.m file; for SMA: order based on order of montage image file, see above)
    pos_idx_hbr(i) = find(all_idx_hbr == sub_group_idx_hbr(i));
end
% index of channel index
pos_idx_hbr % enter these numbers sequentially as index in respective createfigure_Map_PMI_xxx.m file to index variables "data" and "dat_idx". 

