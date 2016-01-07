% Test script for the custom_SPoC function
%
% sebastian.castano@blbt.uni.freiburg.de
% 15. Dec. 2014
close all; clear; clc;
set_localpaths();

%% Set saving paths
% %% Preprocess Data
VP = 'VPpaz_14_12_04'; % Data from the Posner Experiment
runs = [1:10];

options_data ={'fs', 500,...
    'runsLoad', runs, ...
    'critMinMax',120, ...
    'sPosLim', [0 1920], ...
    'timeLim', [150 1000],...
    'ival', [-1000,0],...
    'classDef',{60;'stim'},...
    'notch', true,...
    'filter',[0.2 0.7 90 95],...
    'saveMatlab',1,...
    'loadMatlab',1};

[cnt_eeg, epo, mrk, rtrials] = custom_readPosnerOsciEEG(VP, options_data{:});
rtrials = rtrials | isnan(epo.reactionTime);
idx = find(~rtrials);
epo = custom_selectEpochsPosner(epo,idx);
mrk = mrk_selectEvents(mrk,idx);

[epo_sorted mrk_sorted] = custom_sortPosnerContrast(epo,'mrk',mrk);
epo = epo_sorted{2};
mrk = mrk_sorted{2};

z = epo.reactionTime;



%% Set parameters
% Frequency Bands
fbands = [9, 15];

% Time intervals (prior to stimulus onset)
ival = [-1000, 0];

% Mapping Functions
map_fcts = @(x) x;

% SPoC options
opts = {'applySSD', 0 ,...
    'applyBootstrap', 0,...
    'spocType','lambda',...
    'spocNumOfComp',[]};

mkdir('tmp')
save_name = './tmp/test_customSPoC.mat';
custom_SPoC(cnt_eeg, mrk, z, map_fcts, ival, fbands, save_name, opts{:});