function seq_infos = load_seq_file_infos(seq_file_subpath, markers)
%LOAD_SEQ_FILE_INFOS Loads marker and event information from the seq file
%   Parameters:
%   seq_file_subpath:
%       location of seq. file, relative to VCO data directory
%   markers:
%       struct with (at least) field stimuli; each field of markers.stimuli
%       maps to a numeric marker code
%
%   Return value
%   seq_info:
%       table with event information; one entry for each stimulus (!) marker
%

global PROJECT_SETUP

seq_file = fullfile(PROJECT_SETUP.VCO_DATA_DIR, seq_file_subpath);
seq_file_handle = fopen(seq_file,'r');
%TODO this assumes a fixed number of marker/event columsn, as
%opposed to the python routines
cur_seq_info = textscan(seq_file_handle, '%s%s%s%[^\n\r]', 'Delimiter',  '\t');%,  'ReturnOnError', false);
fclose(seq_file_handle);
frame_event_names = cur_seq_info{2};
event_marker_names = cur_seq_info{3};
event_start_frame = find(cellfun(@length, event_marker_names));

marker_code = zeros(size(event_start_frame));
marker_name = cell(length(event_start_frame), 1);
event_name = cell(length(event_start_frame), 1);
event_type = cell(length(event_start_frame), 1);
event_length = zeros(size(event_start_frame));

for m = 1:length(event_start_frame)
    frame_idx = event_start_frame(m);
    event_name{m} = frame_event_names{frame_idx};
    name_parts = strsplit(event_name{m}, '-');
    event_type{m} = name_parts{2};
    idxs_non_event_frames = find(~cellfun(@length, strfind(frame_event_names, event_name{m})));
    event_length(m)  = min(idxs_non_event_frames(idxs_non_event_frames > frame_idx)) - frame_idx;
    marker_name{m}  = event_marker_names{frame_idx};
    marker_code(m) = getfield(markers.stimuli, marker_name{m});
end

seq_infos = table(event_start_frame, event_name, event_type, event_length, marker_name, marker_code);
end

