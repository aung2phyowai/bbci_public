%% Setup environment
clear, clc, close all;
project_setup();

%% kill existing feedback process in case it's still running
if isunix()
    system('pkill -9 -f "python FeedbackController.py"');
end

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
fbsettings.use_optomarker = true;
fbsettings.image_width = 1242;
fbsettings.image_height = 375;

sequences = {
%   sequence file                           FPS    
    'seq07a_hohenwetterbach_modified2.txt'  10
%       'seq07b_hohenwettersbach.txt'         15
    'seq08b_weiherfeld2_highlighted.txt'    10
    'seq03_kelterstr_modified.txt'          10
    'seq04_hardtwald_modified.txt'          10
%     'seq06_weiherfeld_modified.txt'       20
    'seq05_erbprinzenstr_modified.txt'      10
%     'seq02_autobahn.txt'                  20
    'seq09a_kanord.txt'                     10    
    'seq10_pfinztalstr.txt'                 10
};


%% Setup bbci toolbox
bbci= struct;

max_amp = 26.3;
fs = 100;

bbci.source(1).acquire_fcn= @bbci_acquire_randomSignals;
bbci.source(1).acquire_param= {'clab',{'Cz'}, 'amplitude', max_amp,...
    'fs', fs, 'realtime', 1,...
    'marker_mode', 'pyff_udp', 'marker_udp_port', PROJECT_SETUP.UDP_MARKER_PORT};
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
bbci.control.condition.marker = PROJECT_SETUP.markers.classifier_trigger; %currently not sent by pyff

% defines, where control signals are *sent*
bbci.feedback(1).host = 'localhost';
bbci.feedback(1).port = 12345;
bbci.feedback(1).receiver = 'pyff';

bbci.quit_condition.marker= PROJECT_SETUP.markers.trial_end; 


%% loop over sequences
%reset previous data
for i = 1:size(sequences, 1)
   seqFileName = sequences{i,1};
   seqFPS = sequences{i,2};
   
   fbsettings.param_image_seq_file = fullfile(PROJECT_SETUP.SEQ_DATA_DIR, seqFileName);
   fbsettings.FPS = seqFPS;
   fbOpts = fieldnames(fbsettings);
   
   fprintf('Sending feedback parameters...')
   for optId = 1:length(fbOpts),
       pyff_sendUdp('interaction-signal', fbOpts{optId}, getfield(fbsettings, fbOpts{optId})); %#ok<GFLD>
   end
   fprintf(' Done!\n')
   
   %% Loading data.
   
%    currently not in use due to pyffs socket lifecycle
   % workaround, since command signals are only processed by the IPC
   % channel and not delivered to the Feedback instance
%    fprintf('Preloading ....\n')
%    pyff_sendUdp('interaction-signal', 'trigger_preload','true');
%    
%    waitForMarker(PROJECT_SETUP.markers.preload_completed)
   
   fprintf('Press any key to start playing...\n')
   if (input('Press a to abort, anything else to continue...\n', 's') == 'a')
       break
   end
   
   
   %% Run!
   pyff_sendUdp('interaction-signal', 'command','play');
   
   data(i) = bbci_apply(bbci);
   

    %% Stop!
   pyff_sendUdp('interaction-signal', 'command','stop');
   
   
   validation_stats(data(i))
   
end




%% close
pyff_sendUdp('interaction-signal', 'command','close');
pyff_sendUdp('interaction-signal', 'command','quitfeedbackcontroller');
pyff_sendUdp('close');
disp('UDP connection succesfully closed')

