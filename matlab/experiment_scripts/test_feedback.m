%% Test feedback without BV hardware
%delete everything, including UDP connections and persistent variables
clear all;
clc, close all; 
init_experiment_setup();

experiment_config();

%% start feedback controller and init UDP connection
pyff_start_feedback_controller()
% workaround: for some reason the socket is not initialized until the first
% pyff_sendUdp call from the main file, despite the socket being persistent
pyff_sendUdp('interaction-signal', 'command','stop');

%% Create blocks of sequences

%override for manual testing
% EXPERIMENT_CONFIG.blockStructure = cell(1,1,2);
% EXPERIMENT_CONFIG.blockStructure(1,:,:) = {
% %   sequence file                           FPS
% 'seq_c10_1-weiherfeldb-mod4.txt'    10
% };


%% loop over blocks
for block_no = 0:(EXPERIMENT_CONFIG.block_count - 1)
    block_rows_sel = EXPERIMENT_CONFIG.block_structure.blockNo == block_no;
    current_block = EXPERIMENT_CONFIG.block_structure(block_rows_sel, :);
    
    block_name = sprintf('block%02d', block_no);
    
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

