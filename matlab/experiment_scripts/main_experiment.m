%% Run experiment
%delete everything, including UDP connections and persistent variables
clear all; %#ok<CLSCR>
clc, close all;

%% init global variables PROJECT_SETUP and EXPERIMENT_CONFIG
% path config, start up bbci toolbox
init_experiment_setup();
% config for this experimental run
experiment_config();

%% Start BV recorder (if available)

if PROJECT_SETUP.HARDWARE_AVAILABLE
    system([PROJECT_SETUP.BV_RECORDER_EXECUTABLE ' &'])
    pause(3);
    bvr_sendcommand('stoprecording');
    bbci_acquire_bv('close')
    bvr_sendcommand('loadworkspace', fullfile(PROJECT_SETUP.CONFIG_DIR, PROJECT_SETUP.BV_WORKSPACE_FILE_NAME))
    bvr_sendcommand('viewsignals')
end

%save config
if ~exist(EXPERIMENT_CONFIG.recordDir, 'dir')
    mkdir(EXPERIMENT_CONFIG.recordDir)
end
save(fullfile(EXPERIMENT_CONFIG.recordDir, 'experiment_config.mat'), 'EXPERIMENT_CONFIG');

%% Reaction time task (if enabled)
if EXPERIMENT_CONFIG.fb.reaction_time.enabled
    %% Start feedback and BV controller
    pyff_start_feedback_controller()
    
    
    % workaround: for some reason the socket is not initialized until the first
    % pyff_sendUdp call from the main file, despite the socket being persistent
    pyff_sendUdp('interaction-signal', 'command','stop');
    pyff_sendUdp('interaction-signal', 's:_feedback', EXPERIMENT_CONFIG.fb.reaction_time.python_class_name, 'command','sendinit');
    pyff_send_reaction_time_params()
    pause(0.2)
    pyff_sendUdp('interaction-signal', 'command','play');
    
 
    %% Run reaction time block
    for block_no = 0:(EXPERIMENT_CONFIG.fb.reaction_time.block_count - 1)

        if (input('Enter q to quit, anything else to start new reaction time block...\n', 's') == 'q')
            break
        end
        
        %% setup recording
        % Setup bbci toolbox parameters
        bbci = bbci_setup(['reaction_time_block' num2str(block_no)]);
        %configure brain vision recorder
        if PROJECT_SETUP.HARDWARE_AVAILABLE
            bvr_sendcommand('stoprecording');
            bbci_acquire_bv('close')
            bvr_sendcommand('loadworkspace', fullfile(PROJECT_SETUP.CONFIG_DIR, PROJECT_SETUP.BV_WORKSPACE_FILE_NAME))
            
            bvr_sendcommand('viewsignals')
        end
        
        %% Run!
        pyff_sendUdp('interaction-signal', 'state_command','start_block');
        fprintf('Sent play signal\n')
        
        data = bbci_apply(bbci);
    end
    

    pyff_stop_feedback_controller()

end

%% Visual complexity task

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

%% loop over blocks
%convention: block 0 is familarization
for block_no = 0:(EXPERIMENT_CONFIG.block_count - 1)
    block_rows_sel = EXPERIMENT_CONFIG.block_structure.blockNo == block_no;
    current_block = EXPERIMENT_CONFIG.block_structure(block_rows_sel, :);
    
    block_name = sprintf('block%02d', block_no);

    
    %% Loading data.
    pyff_send_parameters(current_block, block_name);
    pyff_sendUdp('interaction-signal', 'state_command','start_preload');
    fprintf('Preloading...')
%     wait_for_marker(EXPERIMENT_CONFIG.markers.technical.preload_completed)
    stimutil_waitForMarker(bbci_setup('loading'), EXPERIMENT_CONFIG.markers.technical.preload_completed)
    fprintf('complete\n')

    fprintf([' Next block: ', block_name, '\n'])
    for seqIdx = 1:size(current_block, 1)
        fprintf(['  ' current_block.seqName{seqIdx} '\n'])
    end

    if (input('Enter q to quit, anything else to continue...\n', 's') == 'q')
        break
    end
    
    %% setup recording
    % Setup bbci toolbox parameters
    bbci = bbci_setup(block_name);
    %configure brain vision recorder
    if PROJECT_SETUP.HARDWARE_AVAILABLE
        bvr_sendcommand('stoprecording');
        bbci_acquire_bv('close')
        bvr_sendcommand('loadworkspace', fullfile(PROJECT_SETUP.CONFIG_DIR, PROJECT_SETUP.BV_WORKSPACE_FILE_NAME))
        
        bvr_sendcommand('viewsignals')
    end
    
    %% Run!
    pyff_sendUdp('interaction-signal', 'state_command','start_playback');
    fprintf('Sent play signal\n')
    
    data = bbci_apply(bbci);

    if ~any(data.marker.desc == EXPERIMENT_CONFIG.markers.technical.seq_start)
        fprintf('%s\n', ['Playback did not start, consult log in ' EXPERIMENT_CONFIG.feedbackLogDir])
    end

    %% some validation
    if EXPERIMENT_CONFIG.validation.show_validation_stats
        marker_stats(data.marker)
    end
    
end


pyff_stop_feedback_controller()