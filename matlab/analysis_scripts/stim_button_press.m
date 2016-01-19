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

[rt_cnt_pp, rt_mrk_pp, rt_hdr, rt_metadata] = vco_load_experiment('reaction_time', experiment_run, preprocessing_config);
[reaction_times, jitter] = vco_get_reaction_times(rt_mrk_pp, rt_metadata.session.used_config);
med_rt = median(reaction_times);

%% plot reaction times
bar(reaction_times)
hist(reaction_times)
scatter(jitter, reaction_times)

%% Extract relevant epochs
bp_interval = [150 1450];

vco_mrk_button_press = vco_mrk_stimClassFromButton(vco_mrk_pp, vco_metadata.session.used_config, bp_interval);


epo_ival = [-150 800];
vco_epo_button_press = proc_segmentation(vco_cnt_pp, vco_mrk_button_press, epo_ival);
mnt =  mnt_setElectrodePositions(vco_epo_button_press.clab);
mnt_grid= mnt_setGrid(mnt, 'M');
%% Raw PO7

idx_PO7 = strmatch('PO7', vco_cnt_pp.clab);

figure,plot(vco_epo_button_press.t, mean(vco_epo_button_press.x(:,idx_PO7,:),3)); 

%% Raw EOGvu
figure,plot(vco_epo_button_press.t, mean(vco_epo_button_press.x(:,strmatch('EOGvu', vco_cnt_pp.clab),:),3)); 
%% Look at raw  grid


figure, grid_plot(vco_epo_button_press, mnt_grid, struct('YUnit','µV', 'ScalePolicy', '[-12 20]'))

%% compare with cursor screen before
% vco_epo_baseline = proc_segmentation(vco_cnt_pp, vco_mrk_seq_start, [-1150 -200]);
% vco_epo_baseline = proc_baseline(vco_epo_baseline, [-1150 -1000]);
% figure, grid_plot(vco_epo_baseline, mnt_grid, struct('YUnit','µV', 'ScalePolicy', '[-12 20]'))

%% Artifact rejection
%copied from BCI Praktikum
% 1) Min-Max criterion
[~, iArte] = proc_rejectArtifactsMaxMin(vco_epo_button_press, 70, 'CLab', {'F9,10','Fz','AF3,4'});

% 2) Variance criterion
[mrk, rclab, rtrials_var]= reject_varEventsAndChannels(vco_cnt_pp, vco_mrk_button_press,...
        [-150 800]);

% Remove rejected epochs
vco_epo_button_pressed_cleaned = proc_selectEpochs(vco_epo_button_press, 'not', unique([iArte, rtrials_var]));

% Remove rejected Channels
vco_epo_button_pressed_cleaned = proc_selectChannels(vco_epo_button_pressed_cleaned,'not',rclab);

vco_epo_button_pressed_cleaned = proc_baseline(vco_epo_button_pressed_cleaned, [-150 -10]);

%% ...
ivals = [0 med_rt; (med_rt + 50) (med_rt + 350)];
 %figure, plot_scalpPattern(vco_epo_button_press, mnt, [390 500])
%plot_scalpEvolution(vco_epo_seq_start, mnt, ivals)
figure,
% h = plot_scalpEvolutionPlusChannel(vco_epo_button_press, mnt, {'PO7,8', 'Cz'}, ivals, struct('CLim', 'sym'));
h = plot_scalpEvolutionPlusChannel(vco_epo_button_press, mnt, {'PO7,8'}, ivals, struct('CLim', 'sym'));
grid_markTimePoint(med_rt);
%% ...
ivals = [180 240; 290 390];
ivals = [100 150; 150 200; 200 230; 230 260; 260 270; 270 280; 280 290; 290 310]
ivals = [230 260; 300 350; 350 400; 400 450; 450 500; 500 550]
figure,
h = plot_scalpEvolutionPlusChannel(vco_epo_button_pressed_cleaned, mnt, {'PO7', 'Cz'}, ivals, struct('CLim', 'sym'), 'ExtrapolateToZero', 1);

%%
figure, grid_plot(vco_epo_button_pressed_cleaned, mnt_grid, struct('YUnit','µV'))
vco_epo_button_press_auc = proc_aucValues(vco_epo_button_pressed_cleaned)
% AUC metric returns the separability of target vs. non-target

grid_plot(vco_epo_button_pressed_cleaned, mnt_grid, struct('YUnit','µV'))
grid_addBars(vco_epo_button_press_auc);