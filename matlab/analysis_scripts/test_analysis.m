%% just a sample file for i/o 

%delete everything, including persistent variables
clear all;
clc, close all; 
init_analysis_setup();

experiment_name = 'vco_pilot_run';
experiment_run = 'VPtest_15-10-28'; %'VPtest_15-09-09';
block_count = 0;

data_dir = fullfile('/home/henkolk/local_data/audiolab', experiment_run);

tmp = load(fullfile(data_dir, 'experiment_config.mat'), 'EXPERIMENT_CONFIG');
%only temporary, added in future saves
%tmp.EXPERIMENT_CONFIG.block_count = 2*tmp.EXPERIMENT_CONFIG.seqsPerType / tmp.EXPERIMENT_CONFIG.blockSize;
used_config = tmp.EXPERIMENT_CONFIG;
clear tmp

current_block_index = 5;
block_name = sprintf('block%02d', current_block_index);
file_prefix = [experiment_run, '_', experiment_name, '_', block_name];
file_pattern = fullfile(data_dir, [file_prefix '*']);
[cnt, mrk_orig, hdr] = file_readBV(file_pattern, 'fs', 100);

tmp_mrk = cell(size(mrk_orig.event.desc,1), 4);
tmp_mrk(:,1) = mrk_orig.event.type;
tmp_mrk(:, 2) = num2cell(mrk_orig.event.desc);
tmp_mrk(:,3) = num2cell(mrk_orig.time);
tmp_mrk(:,4) = num2cell([0 diff(mrk_orig.time)]);

hist(mrk_orig.event.desc)

% scatter(mrk_orig.time, mrk_orig.event.desc, 64, 'x')

mrk_timed = vco_mrk_timeFromOptic(mrk_orig, used_config);

scatter(mrk_timed.time, mrk_timed.event.desc, 64, 'x')

% marker_stats(mrk_timed)

% idx = util_chanind(cnt, 'x_Optic')
% figure, plot(cnt.x(700:750,util_chanind(cnt,idx)))
% grid on
% hold
% 
% %grid_markTimePoint(2286)
% %      plot([22862/10 - 2200, 22862/10 - 2200], [2600 2750])
% xlabel('Time [samples]')
% ylabel('Potential [µVolt]')
% legend('x_Optic')
% title('Raw Channel')





