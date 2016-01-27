function [ bbci ] = init_recording( rec_name )
%INIT_RECORDING Initializes the bbci struct and recording pipeline
%   Return value is the bbci apply data structure

global PROJECT_SETUP

bbci = bbci_setup(rec_name);
%configure brain vision recorder
if PROJECT_SETUP.HARDWARE_AVAILABLE
    bvr_sendcommand('stoprecording');
    bbci_acquire_bv('close')
    bvr_sendcommand('loadworkspace', fullfile(PROJECT_SETUP.CONFIG_DIR, PROJECT_SETUP.BV_WORKSPACE_FILE_NAME))
    
    bvr_sendcommand('viewsignals')
end

end

