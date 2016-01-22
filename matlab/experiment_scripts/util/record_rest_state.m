function [  ] = record_rest_state( time_rec, name )
%record_rest_state Records eyes open/closed

global EXPERIMENT_CONFIG
global PROJECT_SETUP

pyff_start_feedback_controller()
pyff_sendUdp('interaction-signal', 'command','stop');
pyff_sendUdp('interaction-signal', 's:_feedback', EXPERIMENT_CONFIG.fb.utility.python_class_name, 'command','sendinit');

pause(0.2)
pyff_send_base_parameters()

pause(0.2)
pyff_sendUdp('interaction-signal', 'command','play');
pause(0.2)
pyff_sendUdp('interaction-signal', 'state_command','show_crosshair');
%pyff_sendUdp('interaction-signal', 'state_command','optomarker_loop');

for rstate = {'eyes_open', 'eyes_closed'}
    
    bbci = bbci_setup(strcat(name, '_', rstate{1}));
    bbci.quit_condition.running_time = time_rec;
    
    if PROJECT_SETUP.HARDWARE_AVAILABLE
            bvr_sendcommand('stoprecording');
            bbci_acquire_bv('close')
            bvr_sendcommand('loadworkspace', fullfile(PROJECT_SETUP.CONFIG_DIR, PROJECT_SETUP.BV_WORKSPACE_FILE_NAME))
            
            bvr_sendcommand('viewsignals')
            
            %remove eyetracking in rest state since we don't have markers
            if EXPERIMENT_CONFIG.eye_tracking.enabled
                bbci.source(2) = [];
            end
    end
    
    fprintf('Press a key to start recording with %s recording (%d s) \n', rstate{1}, time_rec);
    pause
    fprintf('starting recording...\n')
    data = bbci_apply(bbci);

    fprintf('finished recording\n')
end

    
pyff_sendUdp('interaction-signal', 'command','stop');
pyff_stop_feedback_controller()

