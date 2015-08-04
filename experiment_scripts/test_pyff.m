%% Setup environment
clear, clc, close all;
setup_visual_complexity();

%% kill existing feedback process in case it's still running
system('pkill -f "python FeedbackController.py"')

%% Start pyff in background

pyffStartupCmd = ['cd ' fullfile(PROJECT_SETUP.PYFF_DIR, 'src')...
    ' && python FeedbackController.py --nogui'...
    ' -a ' PROJECT_SETUP.FEEDBACKS_DIR ...
    '  --loglevel=info --fb-loglevel=debug'...
    ' 2> ' fullfile(PROJECT_SETUP.LOG_DIR, 'pyff.stderr.log')...
    ' 1> ' fullfile(PROJECT_SETUP.LOG_DIR, 'pyff.stdout.log')...
    '  &'];



fprintf('Opening FeedbackController...')
MatlabPath = getenv('LD_LIBRARY_PATH');
setenv('LD_LIBRARY_PATH',getenv('PATH'));
system(pyffStartupCmd,'-echo');
setenv('LD_LIBRARY_PATH',MatlabPath);
fprintf(' Done!\n')


%% Setup UDP connection with the feedback
bbci_feedback.host='localhost';
bbci_feedback.port=12345;
fprintf('Initializing UDP connection...')
pyff_sendUdp('init',  bbci_feedback.host, bbci_feedback.port);
fprintf('Done!\n')
pause(0.1)

fprintf('Initializing feedback...')
pyff_sendUdp('interaction-signal', 's:_feedback', 'ImageSeqViewer', 'command','sendinit');
fprintf(' Done!\n')
%% Send parameters to the feedback
fbsettings = struct;

fbsettings.param_image_seq_file = fullfile(PROJECT_SETUP.SEQ_DATA_DIR, 'seq01_aldi.txt');
fbsettings.FPS = 40;
fbOpts = fieldnames(fbsettings);

fprintf('Sending feedback parameters...')
for optId = 1:length(fbOpts),
    pyff_sendUdp('interaction-signal', fbOpts{optId}, getfield(fbsettings, fbOpts{optId}));
end
fprintf(' Done!\n')


%% Setup bbci toolbox
bbci= struct;

max_amp = 26.3;
fs = 100;

bbci.source(1).acquire_fcn= @bbci_acquire_randomSignals;
bbci.source(1).acquire_param= {'clab',{'Cz'}, 'amplitude', max_amp,...
    'fs', fs, 'realtime', 1,...
    'marker_mode', 'pyff_udp', 'marker_udp_port', 12344};
bbci.source(1).min_blocklength = 10;
bbci.source(1).clab = {'Cz'};
bbci.source(1).record_signals = false;
bbci.source(1).record_basename = '';
bbci.log.output = 'screen&file';
bbci.log.folder = PROJECT_SETUP.BBCI_TMP_DIR;


bbci.signal(1).source = 1;
bbci.signal(1).proc = {};
bbci.signal(1).buffer_size = 25000;

bbci.feature(1).signal = 1;
bbci.feature(1).ival = [-10 0];


C = struct('b', 0, 'w', ones(1,1));
bbci.classifier(1).feature = 1;
bbci.classifier(1).C = C;
bbci.control.condition.marker = 80; %currently not sent by pyff

% defines, where control signals are *sent*
bbci.feedback(1).host = 'localhost';
bbci.feedback(1).port = 12345;
bbci.feedback(1).receiver = 'pyff';

bbci.quit_condition.marker= 65; % Marker.trial_end

%% Run!


pyff_sendUdp('interaction-signal', 'command','play');

data_parking = bbci_apply(bbci);

%% Stop!

pyff_sendUdp('interaction-signal', 'command','stop');

validation_stats(data_parking)
pause;


%% second clip
fbsettings.param_image_seq_file = fullfile(PROJECT_SETUP.SEQ_DATA_DIR, 'seq02_autobahn.txt');
for optId = 1:length(fbOpts),
    pyff_sendUdp('interaction-signal', fbOpts{optId}, getfield(fbsettings, fbOpts{optId}));
end

pyff_sendUdp('interaction-signal', 'command','play');

data_autobahn = bbci_apply(bbci);

%% Stop!

pyff_sendUdp('interaction-signal', 'command','stop');



%% close
pyff_sendUdp('interaction-signal', 'command','close');
pyff_sendUdp('interaction-signal', 'command','quitfeedbackcontroller');
pyff_sendUdp('close');
disp('UDP connection succesfully closed')

%% validation of data

validation_stats(data_autobahn)


