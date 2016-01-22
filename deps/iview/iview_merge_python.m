function iview_merge_python( file_name )
%
% IVIEW_MERGE_PYTHON - merge eeg data files with data from iView recorder, 
% iView data file should have the same name as eeg data with an .iview 
% extension.
%

display(['Merging ' file_name '...'])

[CNT, MRK, HDR] = file_readBV(file_name);
display(['Raw EEG data size: ' num2str(CNT.T)])

iview_file = [ CNT.file '.iview' ];
iview_data = read_iview_data(iview_file);

% indices of marker rows in a file
marker_indecies = find(strcmp(iview_data(:,1), 'M'));
% first and last markers (start and stop of the experiment)
boundary_marker_indecies = marker_indecies([1, end]);

% data between start and stop markers
experiment_data = iview_data([boundary_marker_indecies(1):boundary_marker_indecies(2)+1],:);
% take only iView-related data (remove markers)
gaze_experiment_data = str2double(experiment_data(strcmp(experiment_data(:,1), 'G'),[2 3 4]));
display(['Raw iView data size: ' num2str(size(gaze_experiment_data, 1))])

% timestamps of data, in milliseconds
gaze_timestamps = int64(gaze_experiment_data(:,1) / 1000);
% time difference between current timestamp and the next one
gaze_timestamp_delta = gaze_timestamps(2:end) - gaze_timestamps(1:end-1);
% analyze_time_differences(gaze_timestamp_delta) - possible improvement
% support structure to enumerate through data indeces
gaze_timestamp_indices = 1:size(gaze_timestamp_delta);

% for every index and timestamp delta, take data element and 
% repeat it delta number of times horizontally
resampled_gaze_data = arrayfun(@(index, delta) repmat(gaze_experiment_data(index, [2 3]), delta, 1), gaze_timestamp_indices, gaze_timestamp_delta.', 'UniformOutput', false).';
resampled_gaze_data = cell2mat(resampled_gaze_data);
resampled_gaze_data_rows = size(resampled_gaze_data, 1);
display(['Resampled iView data size: ' num2str(resampled_gaze_data_rows)])

experiment_start_frame = MRK.time(2);
experiment_end_frame = experiment_start_frame + resampled_gaze_data_rows - 1;
current_number_of_channels = size(CNT.x, 2);
additional_channels = [current_number_of_channels+1 current_number_of_channels+2];

CNT.x(experiment_start_frame:experiment_end_frame,additional_channels) = resampled_gaze_data;
CNT.clab(additional_channels) = { 'x_iView' 'y_iView' };
HDR.unitOfClab(additional_channels) = { 'px' 'px' };
file_writeBV([CNT.file 'merged'], CNT, MRK, 'Unit',HDR.unitOfClab)

    function data = read_iview_data(full_file_name)
        
        fid = fopen(full_file_name,'r');
        data = textscan(fid, repmat('%s',1,4), 'delimiter',',', 'CollectOutput',true);
        data = data{1};
        fclose(fid);
        data = data(2:end, :);
        
    end

display('Done!')

end

