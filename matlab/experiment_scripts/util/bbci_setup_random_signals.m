function [ bbci ] = bbci_setup_random_signals( rec_name )
%BBCI_SETUP_RANDOM_SIGNALS Builds config struct for random signals
%   Markers are received via UDP.
global PROJECT_SETUP
global EXPERIMENT_CONFIG

bbci= struct;

fs = 100;
max_amp = 26.3;

if ~exist(EXPERIMENT_CONFIG.recordDir, 'dir')
    mkdir(EXPERIMENT_CONFIG.recordDir)
end
full_rec_name = fullfile(EXPERIMENT_CONFIG.recordDir,...
    [EXPERIMENT_CONFIG.filePrefix '_' rec_name]);
bbciLogDir = fullfile(EXPERIMENT_CONFIG.recordDir, 'bbci_logs');
if ~exist(bbciLogDir, 'dir')
    mkdir(bbciLogDir)
end

bbci.source(1).acquire_fcn= @bbci_acquire_randomSignals;
bbci.source(1).acquire_param= {'clab',{'Cz'}, 'amplitude', max_amp,...
    'fs', fs, 'realtime', 1,...
    'marker_mode', 'pyff_udp', 'marker_udp_port', PROJECT_SETUP.UDP_MARKER_PORT};
bbci.source(1).min_blocklength = 10;
bbci.source(1).clab = {'Cz'};
bbci.source(1).record_signals = false;
bbci.source(1).record_basename = full_rec_name;
if EXPERIMENT_CONFIG.logging.enabled
    bbci.log.output = 'screen&file';
    bbci.log.folder = bbciLogDir;
else
    bbci.log.output = 0;
end


bbci.signal(1).source = 1;
bbci.signal(1).proc = {};
bbci.signal(1).buffer_size = 25000;

bbci.feature(1).signal = 1;
bbci.feature(1).ival = [-10 0];


C = struct('b', 0, 'w', ones(1,1));
bbci.classifier(1).feature = 1;
bbci.classifier(1).C = C;

% defines, where control signals are *sent*
bbci.feedback(1).host = PROJECT_SETUP.UDP_FEEDBACK_HOST;
bbci.feedback(1).port = PROJECT_SETUP.UDP_FEEDBACK_PORT;
bbci.feedback(1).receiver = 'pyff';

bbci.control(1).condition.marker = EXPERIMENT_CONFIG.markers.interactions.button_pressed;
bbci.control(1).fcn = @control_fcn_button_press;
% #bbci_apply_structures bbci_apply_queryMarker

bbci.quit_condition.marker= EXPERIMENT_CONFIG.markers.technical.trial_end;

end

