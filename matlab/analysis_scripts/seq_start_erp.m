%delete everything, including persistent variables
clear all;
clc, close all; 
init_analysis_setup();

%% Set configuration

% analysis_config = struct;
% analysis_config.preprocessing.low_cutoff
% analysis_config.preprocessing.high_cutoff
% analysis_config.preprocessing.target_fs

%% Load main experiment
experiment_name = 'vco_pilot_run';
experiment_run = 'VPpau_15-12-08';
preprocessing_config = struct;
preprocessing_config.lowpass.passband = 34                   ;
preprocessing_config.lowpass.stopband = 40;
preprocessing_config.highpass.passband = 0.7;
preprocessing_config.highpass.stopband = 0.2;
preprocessing_config.time_from_optic = true;
preprocessing_config.target_fs = 100;
preprocessing_config.add_event_labels = true;

[vco_cnt_pp, vco_mrk_pp, vco_hdr, vco_metadata] = vco_load_experiment(experiment_name, experiment_run, preprocessing_config);



%% Extract relevant epochs

vco_mrk_seq_start = mrk_defineClasses(vco_mrk_pp,...
        {vco_metadata.session.used_config.markers.technical.seq_start; 'seq\_start'},...
        'KeepAllMarkers', 0);

vco_epo_seq_start = proc_segmentation(vco_cnt_pp, vco_mrk_seq_start, [-150 800]);

vco_epo_seq_start = proc_baseline(vco_epo_seq_start, [-150 0]);
mnt =  mnt_setElectrodePositions(vco_epo_seq_start.clab);
mnt_grid= mnt_setGrid(mnt, 'M');
%% Raw PO7

idx_PO7 = strmatch('PO7', vco_cnt_pp.clab);

figure,plot(vco_epo_seq_start.t, mean(vco_epo_seq_start.x(:,idx_PO7,:),3)); 

%% Raw EOGvu
figure,plot(vco_epo_seq_start.t, mean(vco_epo_seq_start.x(:,strmatch('EOGvu', vco_cnt_pp.clab),:),3)); 
%% Look at raw  grid


figure, grid_plot(vco_epo_seq_start, mnt_grid, struct('YUnit','µV', 'ScalePolicy', '[-12 20]'))

%% compare with cursor screen before
vco_epo_baseline = proc_segmentation(vco_cnt_pp, vco_mrk_seq_start, [-1150 -200]);
vco_epo_baseline = proc_baseline(vco_epo_baseline, [-1150 -1000]);
figure, grid_plot(vco_epo_baseline, mnt_grid, struct('YUnit','µV', 'ScalePolicy', '[-12 20]'))

%% Artifact rejection
%copied from BCI Praktikum
% 1) Min-Max criterion
[~, iArte] = proc_rejectArtifactsMaxMin(vco_epo_seq_start, 70, 'CLab', {'F9,10','Fz','AF3,4'});

% 2) Variance criterion
[mrk, rclab, rtrials_var]= reject_varEventsAndChannels(vco_cnt_pp, vco_mrk_seq_start,...
        [-150 800]);

% Remove rejected epochs
vco_epo_seq_start_cleaned = proc_selectEpochs(vco_epo_seq_start, 'not', unique([iArte, rtrials_var]));

% Remove rejected Channels
vco_epo_seq_start_cleaned = proc_selectChannels(vco_epo_seq_start_cleaned,'not',rclab);

%% ...
ivals = [180 240; 290 500];
ivals = [50 100; 100 150; 150 200; 200 250];
ivals = [130 200; 200 250; 250 300; 300 350; 350 400; 400 500];
ivals = [130 200; 240 260; 340 350; 360 360;  400 500; 570 630];
ivals = [  700 800];
% plot_scalpPattern(vco_epo_seq_start, mnt, [390 500])
%plot_scalpEvolution(vco_epo_seq_start, mnt, ivals)
figure,
h = plot_scalpEvolutionPlusChannel(vco_epo_seq_start_cleaned, mnt, {'PO7,8', 'Cz'}, ivals, struct('CLim', 'sym'), 'ExtrapolateToZero', 1);
%% ...
ivals = [180 240; 290 390];
figure,
h = plot_scalpEvolutionPlusChannel(vco_epo_seq_start_cleaned, mnt, {'Cz'}, ivals, struct('CLim', 'sym'));