function [ cleanup_handle ] = init_hardware()
%INIT_HARDWARE Initialize BrainVision and eye tracker hardware
%   Returns a cleanup handle, which deinitializes the setup when it goes
%   out of scope

global EXPERIMENT_CONFIG
global PROJECT_SETUP

cleanup_handle = [];

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
    
    if EXPERIMENT_CONFIG.eye_tracking.enabled
        iview_acquire_gaze('persistent_init');
        cleanup_handle = onCleanup(@() iview_acquire_gaze('persistent_close'));
        if strcmp(dinput('Calibrate Eyetracker? (y/n)...\n', 'y'), 'y')
            iview_calibrate('SaveAccuracy', true, ...
            'LogFile', EXPERIMENT_CONFIG.eye_tracking.calibration_log,...
            'LogLabel', 'before_experiment');
        end
    end
end
end

