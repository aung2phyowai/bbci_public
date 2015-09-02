%% Test feedback without BV hardware
%delete everything, including UDP connections and persistent variables
clear all;
clc, close all; 
project_setup();

experiment_config();

%% start feedback controller and init UDP connection
pyff_start_feedback_controller()
% workaround: for some reason the socket is not initialized until the first
% pyff_sendUdp call from the main file, despite the socket being persistent
pyff_sendUdp('interaction-signal', 'command','stop');

%% Create blocks of sequences

blocks = build_block_structure();
block_log_file = fullfile(EXPERIMENT_CONFIG.recordDir, 'block_structure.txt');
write_block_structure(blocks, block_log_file)

%override for manual testing
% blocks = cell(1,1,2);
% blocks(1,:,:) = {
% %   sequence file                           FPS
% 'seq_c10_1-weiherfeldb-mod4.txt'    10
% };


%% loop over blocks
for blockIdx = 1:size(blocks, 1)
    current_block = blocks(blockIdx,:,:);
    
    block_name = sprintf('block%02d', blockIdx);
    
    pyff_send_parameters(current_block, block_name);
    
       
    %% Loading data.
    
    fprintf([' Next block: ', block_name, '\n'])
    if (input('Enter q to quit, anything else to continue...\n', 's') == 'q')
        break
    end
    
    %% Setup bbci toolbox parameters
    bbci = bbci_setup_random_signals(block_name);
    
    %% Run!
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

