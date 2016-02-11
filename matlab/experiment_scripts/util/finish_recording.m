function [ error_count, warning_count ] = finish_recording( data, varargin )
%FINISH_RECORDING Perform post-processing after the trial ended
%   Parameters
%    data    return value of bbci_apply method

global EXPERIMENT_CONFIG
global PROJECT_SETUP

parser = inputParser;
parser.PartialMatching = false;

addParameter(parser, 'ValidateImageSeqPlayback', false);

parse(parser, varargin{:})
opts = parser.Results;

error_count = 0;
warning_count = 0;

if PROJECT_SETUP.HARDWARE_AVAILABLE
    if EXPERIMENT_CONFIG.eye_tracking.enabled
        iview_merge_matlab( data.source(1).record.filename, data.source(2).record.filename,...
            'SyncMarker', EXPERIMENT_CONFIG.markers.technical.pre_start,...
            'ResultSuffix', '_merged');
    end
    
    if ~any(strcmp(data.marker.desc, 'O 1'))
        warning('did not receive any optical markers, make sure the box is functioning')
        warning_count = warning_count + 1;
    end
end

if opts.ValidateImageSeqPlayback
   
    if ~any(data.marker.desc == EXPERIMENT_CONFIG.markers.technical.seq_start)
        warning('Playback did not start, consult log in %s\n', EXPERIMENT_CONFIG.feedbackLogDir)
        error_count = error_count + 1;
    end 
end

end

