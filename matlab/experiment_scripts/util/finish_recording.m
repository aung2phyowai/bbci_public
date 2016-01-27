function [  ] = finish_recording( data )
%FINISH_RECORDING Perform post-processing after the trial ended
%   Parameters
%    data    return value of bbci_apply method

global EXPERIMENT_CONFIG
global PROJECT_SETUP

if PROJECT_SETUP.HARDWARE_AVAILABLE
    if EXPERIMENT_CONFIG.eye_tracking.enabled
        iview_merge_matlab( data.source(1).record.filename, data.source(2).record.filename,...
            'rec_start_marker', EXPERIMENT_CONFIG.markers.technical.pre_start );
    end
end

end

