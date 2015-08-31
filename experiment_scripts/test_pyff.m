%% Test feedback without BV hardware
clear, clc, close all;
project_setup();

%don't care about subject settings, only loading seqs
experiment_config();

%% start feedback controller and init UDP connection
pyff_start_feedback_controller()
% workaround: for some reason the socket is not initialized until the first
% pyff_sendUdp call from the main file, despite the socket being persistent
pyff_sendUdp('interaction-signal', 'command','stop');

%% Set feedback parameters
% sequence file and FPS are added within the for loop
fbsettings = pyff_build_parameters();
sequences = EXPERIMENT_CONFIG.complexSeqs;
% sequences = {
% %   sequence file                           FPS    
% 'seq_c10_1-weiherfeldb-mod4.txt'    10
% };





seqOrder = 1:size(sequences, 1);
if EXPERIMENT_CONFIG.sequences.randomize
    seqOrder = randperm(size(sequences, 1));
end

%% loop over sequences
for i = seqOrder
   seqFileName = sequences{i,1};
   seqFPS = sequences{i,2};
   
   fbsettings.param_image_seq_file = fullfile(PROJECT_SETUP.SEQ_DATA_DIR, seqFileName);
   if exist(fbsettings.param_image_seq_file, 'file') == 0
      % sequence file not accessible, so we don't bother starting the feedback
      fprintf(['Cannot access ', fbsettings.param_image_seq_file, ', aborting!\n'])
      break;
   end
   fbsettings.FPS = seqFPS;
   fbsettings.param_logging_prefix = [EXPERIMENT_CONFIG.filePrefix '_' seqFileName];
   fbOpts = fieldnames(fbsettings);
   
   fprintf('Sending feedback parameters...')
   for optId = 1:length(fbOpts),
       pyff_sendUdp('interaction-signal', fbOpts{optId}, getfield(fbsettings, fbOpts{optId})); %#ok<GFLD>
   end
   fprintf(' Done!\n')
   
   %% Loading data.
   
   fprintf([' Next sequence file ', seqFileName, '\n'])
   if (input('Enter q to quit, anything else to continue...\n', 's') == 'q')
       break
   end
   
   %% Setup bbci toolbox parameters
   fs = 100;
   bbci = bbci_setup_random_signals(seqFileName, fs);
   
   %% Run!
   pyff_sendUdp('interaction-signal', 'command','play');

   data(i) = bbci_apply(bbci);
   

    %% Stop!
   pyff_sendUdp('interaction-signal', 'command','stop');
   
   if EXPERIMENT_CONFIG.validation.show_validation_stats
       validation_stats(data(i))
   end
   
end




%% close
pyff_sendUdp('interaction-signal', 'command','close');
pyff_sendUdp('interaction-signal', 'command','quitfeedbackcontroller');
pyff_sendUdp('close');
disp('UDP connection successfully closed')

