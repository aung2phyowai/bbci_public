function [ bbci ] = bbci_setup( rec_name )
%BBCI_SETUP Builds config struct for BBCI toolbox
%   based on the value of PROJECT_SETUP.HARDWARE_AVAILABLE either
%    BV recorder or random signals are used
global PROJECT_SETUP
global EXPERIMENT_CONFIG


if ~exist(EXPERIMENT_CONFIG.recordDir, 'dir')
    mkdir(EXPERIMENT_CONFIG.recordDir)
end
full_rec_name = fullfile(EXPERIMENT_CONFIG.recordDir,...
    [EXPERIMENT_CONFIG.filePrefix '_' rec_name]);
bbciLogDir = fullfile(EXPERIMENT_CONFIG.recordDir, 'bbci_logs');
if ~exist(bbciLogDir, 'dir')
    mkdir(bbciLogDir)
end

bbci= struct;

if PROJECT_SETUP.HARDWARE_AVAILABLE
    bbci.source(1).acquire_fcn= @bbci_acquire_bv;
    bbci.source(1).acquire_param= {'clab',{'*'}};
    bbci.source(1).min_blocklength = 10;
    bbci.source(1).record_signals = true;

    bbci.signal(1).source = 1;
    bbci.signal(1).proc = {};
    bbci.signal(1).buffer_size = 10;
else
    fs = 100;
    max_amp = 26.3;
    bbci.source(1).acquire_fcn= @bbci_acquire_randomSignals;
    bbci.source(1).acquire_param= {'clab',{'Cz'}, 'amplitude', max_amp,...
        'fs', fs, 'realtime', 1,...
        'marker_mode', 'pyff_udp', 'marker_udp_port', PROJECT_SETUP.UDP_MARKER_PORT};
    bbci.source(1).min_blocklength = 10;
    bbci.source(1).clab = {'Cz'};
    bbci.source(1).record_signals = false;

    bbci.signal(1).source = 1;
    bbci.signal(1).proc = {};
    bbci.signal(1).buffer_size = 25000;
end


bbci.source(1).record_basename = full_rec_name;
if EXPERIMENT_CONFIG.logging.enabled
    bbci.log.output = 'screen&file';
    bbci.log.folder = bbciLogDir;
else
    bbci.log.output = 0;
end

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

bbci.quit_condition.marker= EXPERIMENT_CONFIG.markers.technical.standby_start;
%based on stimutil_waitForMarker

end

