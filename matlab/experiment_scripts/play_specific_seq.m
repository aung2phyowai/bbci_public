%% Play a specific video sequence
% e.g., to ask subject about specific reactions
%delete everything, including UDP connections and persistent variables
clear all; %#ok<CLSCR>
clc, close all;

%% init global variables PROJECT_SETUP and EXPERIMENT_CONFIG
% path config, start up bbci toolbox
init_experiment_setup();
% config for this experimental run
experiment_config();



%% Start feedback
pyff_start_feedback_controller()

% workaround: for some reason the socket is not initialized until the first
% pyff_sendUdp call from the main file, despite the socket being persistent
pyff_sendUdp('interaction-signal', 'command','stop');

%technically, we start playing here, although the feedback will still be in
%standby
fprintf('Initializing feedback...')
pyff_sendUdp('interaction-signal', 's:_feedback', EXPERIMENT_CONFIG.fb.img_seq.python_class_name, 'command','sendinit');
pause(0.2)
fprintf(' Done!\n')
pyff_send_parameters(EXPERIMENT_CONFIG.block_structure(false,:), 'standby'); %send base parameters with empty block
pyff_sendUdp('interaction-signal', 'command','play');


warning('no EEG will be recorded')
%% Choose scene

search_term = input('Please enter a search term for the sequence\n', 's');
candidate_idxes = cellfun(@length, strfind(EXPERIMENT_CONFIG.block_structure.seqName, search_term)) > 0;
candidates = unique(EXPERIMENT_CONFIG.block_structure.seqName( candidate_idxes));

for seqIdx = 1:size(candidates, 1)
    fprintf([num2str(seqIdx) '  ' candidates{seqIdx} '\n'])
end

selected_index = dinput('Please select one of the above sequences\n', 1);
selected_seq_name = candidates{selected_index};

%% Playback

block_idx = find(strcmp(EXPERIMENT_CONFIG.block_structure.seqName, selected_seq_name), 1);
current_block = EXPERIMENT_CONFIG.block_structure(block_idx, :);
block_name = sprintf('single_seq_%02d', block_idx);

pyff_send_parameters(current_block, block_name);
pyff_sendUdp('interaction-signal', 'state_command','start_preload');
fprintf('Preloading...')
%     wait_for_marker(EXPERIMENT_CONFIG.markers.technical.preload_completed)
stimutil_waitForMarker(bbci_setup('loading'), EXPERIMENT_CONFIG.markers.technical.preload_completed)
fprintf('complete\n')

fprintf(['playing ' selected_seq_name '\n'])

if (~strcmp(input('Enter q to quit, anything else to continue...\n', 's'), 'q'))
    pyff_sendUdp('interaction-signal', 'state_command','start_playback');
    fprintf('Sent play signal\n')
    
    stimutil_waitForMarker(bbci_setup('playback'), EXPERIMENT_CONFIG.markers.technical.standby_start)
end

pyff_stop_feedback_controller()