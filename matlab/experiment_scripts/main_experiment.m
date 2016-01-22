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
    if strcmp(EXPERIMENT_CONFIG.VPcode, 'VPtest')
         if dinput('Using test VP code, are you sure (y/n) ...\n', 'n') ~= 'y'
             error('test VP code on experiment machine')
         end
    end
    
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

if EXPERIMENT_CONFIG.eye_tracking.enabled
    iview_acquire_gaze('persistent_init');
    cleaner = onCleanup(@() iview_acquire_gaze('persistent_close'));
    if strcmp(dinput('Calibrate Eyetracker? (y/n)...\n', 'y'), 'y')
        iview_calibrate()
    end
end

%% Record rest state
if (EXPERIMENT_CONFIG.rest_state.enabled && ...
    strcmp(dinput('Record rest state (y/n)...\n', 'y'), 'y'))
	record_rest_state(EXPERIMENT_CONFIG.rest_state.duration, 'beginning')
else
    warning('skipping rest state')
end

%% Reaction time task (if enabled)
if EXPERIMENT_CONFIG.reaction_time_recording.enabled
    %% Start feedback and BV controller
    pyff_start_feedback_controller()
    
    
    % workaround: for some reason the socket is not initialized until the first
    % pyff_sendUdp call from the main file, despite the socket being persistent
    pyff_sendUdp('interaction-signal', 'command','stop');
    pyff_sendUdp('interaction-signal', 's:_feedback', EXPERIMENT_CONFIG.fb.reaction_time.python_class_name, 'command','sendinit');
    pause(0.2)
    pyff_send_reaction_time_params()
    pause(0.2)
    pyff_sendUdp('interaction-signal', 'command','play');
    
 
    %% Run reaction time block
    %convention: block 0 is sample
    rt_block_no = dinput(['Enter next block number; i>' num2str(EXPERIMENT_CONFIG.fb.reaction_time.block_count) '  to quit\n'], 0);
    while rt_block_no <= EXPERIMENT_CONFIG.fb.reaction_time.block_count 

        if (input(['Enter q to quit, anything else to start new reaction time block' num2str(rt_block_no) '...\n'], 's') == 'q')
            break
        end
        
        %% setup recording
        % Setup bbci toolbox parameters
        bbci = bbci_setup(sprintf('reaction_time_block%02d', rt_block_no));
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
        rt_block_no = dinput(['Enter next block number; i>' num2str(EXPERIMENT_CONFIG.fb.reaction_time.block_count) '  to quit\n'], rt_block_no + 1);
    end
    

    pyff_sendUdp('interaction-signal', 'command','stop');
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
%convention: blocks < 1 are familarization

min_block_no = min(EXPERIMENT_CONFIG.block_structure.blockNo);
max_block_no = max(EXPERIMENT_CONFIG.block_structure.blockNo);

block_no = dinput(['Enter next block number (' num2str(min_block_no) '<=i<=' num2str(max_block_no) '), or i> ' num2str(max_block_no) '  to quit\n'], min_block_no);
while min_block_no <= block_no && block_no <= max_block_no
    block_rows_sel = EXPERIMENT_CONFIG.block_structure.blockNo == block_no;
    current_block = EXPERIMENT_CONFIG.block_structure(block_rows_sel, :);
    
    block_name = sprintf('block%02d', block_no);

    
    %% Loading data.
    pyff_send_parameters(current_block, block_name);
    pyff_sendUdp('interaction-signal', 'state_command','start_preload');
    fprintf('Preloading...')
%     wait_for_marker(EXPERIMENT_CONFIG.markers.technical.preload_completed)
    tmp_bbci = bbci_setup('loading');
    if EXPERIMENT_CONFIG.eye_tracking.enabled
        tmp_bbci.source(2) = [];
    end
    stimutil_waitForMarker(tmp_bbci, EXPERIMENT_CONFIG.markers.technical.preload_completed)
    fprintf('complete\n')

    fprintf([' Next block: ', block_name, '; last block is ' num2str(max_block_no) ' \n'])
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

    block_no = dinput(['Enter next block number (' num2str(min_block_no) '<=i<=' num2str(max_block_no) '), or i> ' num2str(max_block_no) '  to quit\n'], block_no + 1);
end


pyff_stop_feedback_controller()

if (EXPERIMENT_CONFIG.rest_state.enabled && ...
    strcmp(dinput('Record rest state (y/n)...\n', 'y'), 'y'))
	record_rest_state(EXPERIMENT_CONFIG.rest_state.duration, 'end')
else
    warning('skipping rest state')
end