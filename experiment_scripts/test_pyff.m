%% Setup environment
clear, clc, close all;
project_setup();

%% start feedback controller and init UDP connection
pyff_start_feedback_controller()


%% Set feedback parameters
% sequence file and FPS are added within the for loop
fbsettings = struct;
fbsettings.use_optomarker = true;
fbsettings.image_width = 1242;
fbsettings.image_height = 375;

sequences = {
%   sequence file                           FPS    
    'seq07a_hohenwetterbach_modified2.txt'  10
%       'seq07b_hohenwettersbach.txt'         15
%     'seq08b_weiherfeld2_highlighted.txt'    10
    'seq03_kelterstr_modified.txt'          10
    'seq04_hardtwald_modified.txt'          10
%     'seq06_weiherfeld_modified.txt'       20
    'seq05_erbprinzenstr_modified.txt'      10
%     'seq02_autobahn.txt'                  20
    'seq09a_kanord.txt'                     10    
    'seq10_pfinztalstr.txt'                 10
};


%% Setup bbci toolbox parameters
fs = 100;
bbci = bbci_setup_random_signals(fs);


%% loop over sequences
for i = 1:size(sequences, 1)
   seqFileName = sequences{i,1};
   seqFPS = sequences{i,2};
   
   fbsettings.param_image_seq_file = fullfile(PROJECT_SETUP.SEQ_DATA_DIR, seqFileName);
   if exist(fbsettings.param_image_seq_file, 'file') == 0
      % sequence file not accessible, so we don't bother starting the feedback
      error(['Cannot access ', fbsettings.param_image_seq_file, ', aborting!'])
   end
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
   
   if (input('Enter q to quit, anything else to continue...\n', 's') == 'q')
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

