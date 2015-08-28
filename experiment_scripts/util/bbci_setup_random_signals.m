function [ bbci ] = bbci_setup_random_signals( fs )
%BBCI_SETUP_RANDOM_SIGNALS Builds config struct for random signals
%   Markers are received via UDP.
global PROJECT_SETUP
global EXPERIMENT_CONFIG

bbci= struct;

max_amp = 26.3;

bbci.source(1).acquire_fcn= @bbci_acquire_randomSignals;
bbci.source(1).acquire_param= {'clab',{'Cz'}, 'amplitude', max_amp,...
    'fs', fs, 'realtime', 1,...
    'marker_mode', 'pyff_udp', 'marker_udp_port', PROJECT_SETUP.UDP_MARKER_PORT};
bbci.source(1).min_blocklength = 10;
bbci.source(1).clab = {'Cz'};
bbci.source(1).record_signals = false;
bbci.source(1).record_basename = '';
if EXPERIMENT_CONFIG.logging.enabled
    bbci.log.output = 'screen&file';
    bbci.log.folder = PROJECT_SETUP.BBCI_TMP_DIR;
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
bbci.control.condition.marker = EXPERIMENT_CONFIG.markers.classifier_trigger; %currently not sent by pyff

% defines, where control signals are *sent*
bbci.feedback(1).host = PROJECT_SETUP.UDP_FEEDBACK_HOST;
bbci.feedback(1).port = PROJECT_SETUP.UDP_FEEDBACK_PORT;
bbci.feedback(1).receiver = 'pyff';

bbci.quit_condition.marker= EXPERIMENT_CONFIG.markers.trial_end;

end

