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
preprocessing_config.highpass.passband = 0.7;
preprocessing_config.highpass.stopband = 0.2;
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

stimuli_marker_codes = struct2array(vco_metadata.session.used_config.markers.stimuli);
hazard_mask = vco_metadata.session.used_config.markers.meta.hazardous_mask;
hazard_marker_codes = stimuli_marker_codes(logical(bitand(stimuli_marker_codes, hazard_mask)));
nonhazard_marker_codes = stimuli_marker_codes(~logical(bitand(stimuli_marker_codes, hazard_mask)));

vco_mrk_hazard_stim = mrk_defineClasses(vco_mrk_pp,...
        {hazard_marker_codes nonhazard_marker_codes; ...
        'haz', 'nohaz'},...
        'KeepAllMarkers', 0);

vco_epo_hazard = proc_segmentation(vco_cnt_pp, vco_mrk_hazard_stim, [-150 800]);

mnt =  mnt_setElectrodePositions(vco_epo_hazard.clab);
mnt_grid= mnt_setGrid(mnt, 'M');

%% Artifact rejection
%copied from BCI Praktikum
% 1) Min-Max criterion
[~, iArte] = proc_rejectArtifactsMaxMin(vco_epo_hazard, 70, 'CLab', {'F9,10','Fz','AF3,4'});

% 2) Variance criterion
[mrk, rclab, rtrials_var]= reject_varEventsAndChannels(vco_cnt_pp, vco_mrk_hazard_stim,...
        [-150 800]);

% Remove rejected epochs
vco_epo_hazard_cleaned = proc_selectEpochs(vco_epo_hazard, 'not', unique([iArte, rtrials_var]));

% Remove rejected Channels
vco_epo_hazard_cleaned = proc_selectChannels(vco_epo_hazard_cleaned,'not',rclab);

% Baselining

vco_epo_hazard_cleaned = proc_baseline(vco_epo_hazard_cleaned, [-150 -10]);

vco_epo_hazard_cleaned_rsqs = proc_rSquareSigned(vco_epo_hazard_cleaned);
%% Plot classes
ivals = [med_rt (med_rt + 100); (med_rt + 250) (med_rt + 350)];

ivals = [100 150; 150 200; 200 250; 250 350; 350 450; 450 550];
ivals = [100 150; 150 200; 200 250; 290 310; 390 410; 450 550];
ivals = [100 150; 150 200]%; 200 230]%; 230 260]
ivals = [ 150 200; 290 340]
ivals = [ 380 420; 450 550]
% ivals = [50 100; 100 130; 130 160; 160 190; 190 220]
% ivals = [290 310; 310 350; 350 400]
% ivals = [100 150; 150 200; 200 230; 230 260; 260 270; 270 280; 280 290; 290 310; 390 410; 450 550];


h1 = figure,
h = plot_scalpEvolutionPlusChannelPlusrSquared(vco_epo_hazard_cleaned, vco_epo_hazard_cleaned_rsqs, mnt, {'PO7', 'Cz'}, ivals, struct('CLim', 'sym',     'GlobalCLim', 1), 'ExtrapolateToZero', 1);
% h = plot_scalpEvolutionPlusChannel(vco_epo_hazard_cleaned, mnt, {'PO7', 'Cz'}, ivals, struct('CLim', 'sym',     'GlobalCLim', 1), 'ExtrapolateToZero', 1);

fig_name =  'erp_rsqs_hazard';
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