%% Setup environment
clear, clc, close all;
project_setup();

%% start feedback controller and init UDP connection
pyff_start_feedback_controller()
% workaround: for some reason the socket is not initialized until the first
% pyff_sendUdp call from the main file, despite the socket being persistent
pyff_sendUdp('interaction-signal', 'command','stop');

%% Set feedback parameters
% sequence file and FPS are added within the for loop
fbsettings = struct;
fbsettings.use_optomarker = true;
fbsettings.image_width = 1242;
fbsettings.image_height = 375;

sequences = {
%   sequence file                           FPS    
% 'seq_c01_1-waldstadta.txt' 10
% 'seq_c01_2-waldstadta.txt' 10
% 'seq_c02_1-waldstadtb.txt' 10
% % 'seq_c02_2-waldstadtb.txt' 10
% % 'seq_c03_1-knielingen.txt' 10
% 'seq_c04_1-bismarckstr.txt' 10
% 'seq_c05_1-pfinztalstr.txt' 10
% 'seq_c05_2-pfinztalstr.txt' 10
% 'seq_c06_1-kelterstr.txt' 10
% 'seq_c06_2-kelterstr.txt' 10
% 'seq_c07_1-erbprinzenstr.txt' 10
% 'seq_c07_2-erbprinzenstr.txt' 10
% 'seq_c07_3-erbprinzenstr.txt' 10
% 'seq_c08_1-kirchfeld.txt' 10
% 'seq_c08_2-kirchfeld.txt' 10
% 'seq_c08_3-kirchfeld.txt' 10
% 'seq_c08_4-kirchfeld.txt' 10
% 'seq_c08_5-kirchfeld.txt' 10
'seq_c09_1-weiherfelda-mod5-v1.txt' 10
% 'seq_c09_1-weiherfelda-mod5-v2.txt' 10
'seq_c09_1-weiherfelda-mod5-v3.txt' 10
'seq_c09_1-weiherfelda.txt' 10
'seq_c09_2-weiherfelda.txt' 10
'seq_c09_3-weiherfelda.txt' 10
'seq_c10_1-weiherfeldb.txt' 10
'seq_c10_2-weiherfeldb.txt' 10
'seq_c10_3-weiherfeldb.txt' 10
'seq_c10_4-weiherfeldb.txt' 10
'seq_c10_5-weiherfeldb.txt' 10
'seq_c10_6-weiherfeldb.txt' 10
'seq_c10_8-weiherfeldb.txt' 10

%     'seq_cAll_test.txt'                        10
%     'seq07a_hohenwetterbach_modified3.txt'  5
%     'seq07b_hohenwettersbach.txt'           10
%     'seq06a_weiherfeld_modified3.txt'       10
%     'seq08b_weiherfeld2_highlighted.txt'    10
%     'seq03_kelterstr_modified.txt'          10
    'seq04_hardtwald.txt'          10
%     'seq05_erbprinzenstr_modified.txt'      10
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
      fprintf(['Cannot access ', fbsettings.param_image_seq_file, ', aborting!\n'])
      break;
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
   
   fprintf([' Next sequence file ', seqFileName, '\n'])
   if (input('Enter q to quit, anything else to continue...\n', 's') == 'q')
       break
   end
   
   
   %% Run!
   pyff_sendUdp('interaction-signal', 'command','play');
   
   data(i) = bbci_apply(bbci);
   

    %% Stop!
   pyff_sendUdp('interaction-signal', 'command','stop');
   
   if PROJECT_SETUP.validation.show_validation_stats
       validation_stats(data(i))
   end
   
end




%% close
pyff_sendUdp('interaction-signal', 'command','close');
pyff_sendUdp('interaction-signal', 'command','quitfeedbackcontroller');
pyff_sendUdp('close');
disp('UDP connection succesfully closed')

