%delete everything, including persistent variables
clear all;
clc, close all; 
init_analysis_setup();

%% load data
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

%% select seq
vco_mrk_seq_start = mrk_defineClasses(vco_mrk_pp,...
        {vco_metadata.session.used_config.markers.technical.seq_start; 'seq_start'},...
        'KeepAllMarkers', 0);

vco_epo_seq_start = proc_segmentation(vco_cnt_pp, vco_mrk_seq_start, [0 20000]);

%% 

alpha_band = [9 12];

seq_spec = proc_spectrum(vco_epo_seq_start, [7 15], kaiser(vco_epo_seq_start.fs,2))
% seq_spectogram = proc_spectrogram(vco_epo_seq_start, [7 15])

spectogram = custom_plotFreqSpectrum(seq_spec, 'showFreqBand', true, 'freqBand', [7 15])


%%
channel_idx = util_chanind(vco_epo_seq_start, 'Pz');
SpectrogramExample(vco_epo_seq_start.x(:, channel_idx, 2), vco_epo_seq_start.fs)
spectogram(vco_epo_seq_start.x(:, :, 1))

%%

spec_cnt = proc_spectrum(vco_cnt_pp, [1 40], kaiser(vco_cnt_pp.fs,2));
grid on

% By default, windows are selected with half-window overlap. 
% Pitfall: If windows don't fit the epoch length, the last interval of your data might NOT be analyzed!
% plots the spectrum of all 50 channels; 
plot(spec_cnt.t,spec_cnt.x)
spec_cnt = proc_selectChannels(spec_cnt, {'C3', 'Cz', 'C4', 'POz','Pz','F5'}); %select channels
figure, plot(spec_cnt.t, spec_cnt.x), 
legend(spec_cnt.clab)

%% plot alpha
custom_plotFreqSpectrum(spectogram)