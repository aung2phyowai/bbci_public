%% Run experiment with BV hardware
clear, clc, close all;

% path config, start up bbci toolbox
init_experiment_setup();
% config for this experimental run
experiment_config();

%% Start feedback and BV controller
pyff_start_feedback_controller()
% workaround: for some reason the socket is not initialized until the first
% pyff_sendUdp call from the main file, despite the socket being persistent
pyff_sendUdp('interaction-signal', 'command','stop');

system([PROJECT_SETUP.BV_RECORDER_EXECUTABLE ' &'])

pause(3);

%% Create blocks of sequences

%override for manual testing
% EXPERIMENT_CONFIG.blockStructure = cell(1,1,2);
% EXPERIMENT_CONFIG.blockStructure(1,:,:) = {
% %   sequence file                           FPS
% 'seq_c10_1-weiherfeldb-mod4.txt'    10
% };

%save config
save(fullfile(EXPERIMENT_CONFIG.recordDir, 'experiment_config.mat'), 'EXPERIMENT_CONFIG');

%% loop over blocks
for blockIdx = 1:size(EXPERIMENT_CONFIG.blockStructure, 1)
    current_block = EXPERIMENT_CONFIG.blockStructure(blockIdx,:,:);
    
    block_name = sprintf('block%02d', blockIdx);
    
    pyff_send_parameters(current_block, block_name);
    
    
    %% Loading data.
    
    fprintf([' Next block: ', block_name, '\n'])
    if (input('Enter q to quit, anything else to continue...\n', 's') == 'q')
        break
    end
    
    
    
    
    %% setup recording
    % Setup bbci toolbox parameters
    
    bbci = bbci_setup_bv_recording(block_name);
    bvr_sendcommand('stoprecording');
    bbci_acquire_bv('close')
    bvr_sendcommand('loadworkspace', fullfile(PROJECT_SETUP.EXPERIMENT_SCRIPTS_DIR, 'extra_files', PROJECT_SETUP.BV_WORKSPACE_FILE_NAME))
    
    bvr_sendcommand('viewsignals')
    
    
    %% Run feedback
    pyff_sendUdp('interaction-signal', 'command','play');
    fprintf('Sent play signal\n')
    
    data = bbci_apply(bbci);
    
    %% Stop!
    pyff_sendUdp('interaction-signal', 'command','stop');
    
    if EXPERIMENT_CONFIG.validation.show_validation_stats
        validation_stats(data)
    end
    
end




%% close
pyff_sendUdp('interaction-signal', 'command','close');
pyff_sendUdp('interaction-signal', 'command','quitfeedbackcontroller');
pyff_sendUdp('close');
disp('UDP connection successfully closed')

