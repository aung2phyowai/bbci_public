%delete everything, including persistent variables
clear all;
clc, close all; 
init_analysis_setup();

%% Load main experiment
experiment_name = 'vco_pilot_run';
experiment_run = 'VPpau_15-12-08';
preprocessing_config = struct;
preprocessing_config.lowpass.passband = 35;
preprocessing_config.lowpass.stopband = 40;
preprocessing_config.highpass.passband = 1.0;
preprocessing_config.highpass.stopband = 0.6;
preprocessing_config.time_from_optic = true;
preprocessing_config.target_fs = 100;

[vco_cnt_pp, vco_mrk_pp, vco_hdr, vco_metadata] = vco_load_experiment(experiment_name, experiment_run, preprocessing_config);

[rt_cnt_pp, rt_mrk_pp, rt_hdr, rt_metadata] = vco_load_experiment('reaction_time', experiment_run, preprocessing_config);
[reaction_times, jitter] = vco_get_reaction_times(rt_mrk_pp, rt_metadata.session.used_config);
med_rt = median(reaction_times);

% %% Extract relevant epochs
% 
% vco_mrk_seq_start = mrk_defineClasses(vco_mrk_pp,...
%         {vco_metadata.session.used_config.markers.technical.seq_start; 'seq_start'},...
%         'KeepAllMarkers', 0);
% 
% vco_epo_seq_start = proc_segmentation(vco_cnt_pp, vco_mrk_seq_start, [-150 800]);
% 
% vco_epo_seq_start = proc_baseline(vco_epo_seq_start, [-150 0]);
% mnt =  mnt_setElectrodePositions(vco_epo_seq_start.clab);
% mnt_grid= mnt_setGrid(mnt, 'M');


%% Extract relevant epochs

button_marker_codes = vco_metadata.session.used_config.markers.interactions.button_pressed;


vco_mrk_btn_press = mrk_defineClasses(vco_mrk_pp,...
        {button_marker_codes ; ...
        'press', },...
        'KeepAllMarkers', 0);

vco_epo_btn_press_ival = [-800 300];
vco_epo_btn_press = proc_segmentation(vco_cnt_pp, vco_mrk_btn_press, vco_epo_btn_press_ival);

mnt =  mnt_setElectrodePositions(vco_epo_btn_press.clab);
mnt_grid= mnt_setGrid(mnt, 'M');

%% Artifact rejection
%copied from BCI Praktikum
% 1) Min-Max criterion
[~, iArte] = proc_rejectArtifactsMaxMin(vco_epo_btn_press, 70, 'CLab', {'F9,10','Fz','AF3,4'});

% 2) Variance criterion
[mrk, rclab, rtrials_var]= reject_varEventsAndChannels(vco_cnt_pp, vco_mrk_btn_press,...
        vco_epo_btn_press_ival);

% Remove rejected epochs
vco_epo_btn_press_cleaned = proc_selectEpochs(vco_epo_btn_press, 'not', unique([iArte, rtrials_var]));

% Remove rejected Channels
vco_epo_btn_press_cleaned = proc_selectChannels(vco_epo_btn_press_cleaned,'not',rclab);

% Baselining
baseline_ival = [vco_epo_btn_press_ival(1) (vco_epo_btn_press_ival(1) + 100)];
baseline_ival = [-800 -700];
vco_epo_btn_press_cleaned = proc_baseline(vco_epo_btn_press_cleaned, baseline_ival);

vco_epo_btn_press_cleaned_rsqs = proc_rSquareSigned(vco_epo_btn_press_cleaned);
%% Plot classes

% ivals = [-1200 -1100; -1100 -900; -900 -700; -700 -500; -500 -300; -300 -100; -100 0; 0 100; 100 200]

ivals = [-220 -190; -120 -70; -20 30; 50 100];
% ivals = [-370 -340; -250 -200; -120 -70]
% ivals = [ -20 30; 50 100];

h1 = figure,
% h = plot_scalpEvolutionPlusChannelPlusrSquared(vco_epo_btn_press_cleaned, vco_epo_btn_press_cleaned_rsqs, mnt, {'PO7', 'Cz'}, ivals, struct('CLim', 'sym',     'GlobalCLim', 1), 'ExtrapolateToZero', 1);
h = plot_scalpEvolutionPlusChannel(vco_epo_btn_press_cleaned, mnt, {'C3', 'POz'}, ivals, struct('CLim', 'sym',     'GlobalCLim', 1), 'ExtrapolateToZero', 1);
grid_markTimePoint(-med_rt);
fig_name =  'erp_btn_press';
% fig_name =  'erp_hazard';
ival_str = '';
for k=1:size(ivals, 1)
   ival_str = strcat(ival_str, '_', num2str(ivals(k, 1)), '-', num2str(ivals(k, 2)));
end
tic
savepic(fullfile(PROJECT_SETUP.PLOT_DIR, [fig_name ival_str]), 'pdf', '-dbg')
toc
% util_printFigure(fullfile(PROJECT_SETUP.PLOT_DIR, [fig_name ival_str '_3']), 'Format', 'pdf', 'PaperSize', 'auto')
% tic
% saveas(h1, fullfile(PROJECT_SETUP.PLOT_DIR, [fig_name ival_str '2.pdf']), 'pdf')
% toc