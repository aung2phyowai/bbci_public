function [ mrk_updated, display_delays ] = vco_mrk_timeFromOptic( mrk_orig, used_config )
%vco_mrk_timeFromOptic Replaces feedback marker times with the one from the
%optical sensor
%adapted from famox_analysis:tools/processing/custom_sortSviptMarkers.m
%     we have three types of markers
%      - markers sent by the feedback (via parallel) 
%      - optical markers triggered by feedback display
%         -> should be 1:1 with feedback markers -> use only time
%      - user "response" (interaction) markers 

    feedback_marker_codes = [struct2array(used_config.markers.technical),...
        struct2array(used_config.markers.stimuli)];
    
    %stimulus
    mrk_feedback_markers = mrk_defineClasses(mrk_orig,...
        {feedback_marker_codes; 'feedback_markers'},...
        'KeepAllMarkers', 0);
    

    %"response", we can take it directly from original class
    mrk_optic = mrk_selectClasses(mrk_orig, 'O  1');
    
    
    [mrk_fbopt_matched, i_matched_feedback, i_matched_optic] = mrk_matchStimWithResp(...
        mrk_feedback_markers, mrk_optic,...
        'MaxLatency', 200,...
        'MinLatency', -50,...
        'AllowOvershoot', 1);%,...
%         'MissingresponsePolicy', 'accept')

    if size(i_matched_feedback, 2) ~= size(i_matched_optic, 2)
       error('matching failed with different numbers of feedback and optical markers')
    end
    if size(mrk_fbopt_matched.time, 2) ~= size(mrk_feedback_markers.time, 2)
        i_missing = ~ismember(1:size(mrk_feedback_markers.time, 2), i_matched_feedback);
        warning(['found ' num2str(size(mrk_fbopt_matched.time, 2)) ' matches with optical markers for '...
            num2str(size(mrk_feedback_markers.time, 2)) ' feedback markers;'...
            ' optical missing for markers ' strcat(num2str(mrk_feedback_markers.event.desc(i_missing)'))...
            ' at time ' strcat(num2str(mrk_feedback_markers.time(i_missing)))])
    end
    
    delays = mrk_optic.time(i_matched_optic) - mrk_feedback_markers.time(i_matched_feedback); 
    
    mrk_interactions = mrk_defineClasses(mrk_orig,...
        {struct2array(used_config.markers.interactions); 'interaction_markers'},...
        'KeepAllMarkers', 0);
    
    mrk_updated = mrk_feedback_markers;
    %update the time based on the matched optomarker,
    mrk_updated.time(i_matched_feedback) = mrk_optic.time(i_matched_optic);
    
    % use mean delay if no match
    i_unmatched_feedback = setdiff(1:length(mrk_feedback_markers.time), i_matched_feedback);
    if ~isempty(i_unmatched_feedback)
        if isempty(delays)
            time_shift = dinput('No optical marker found. Enter manual shift in ms for all feedback markers: \n', 0)
        else
            time_shift = round(mean(delays));
        end
        warning('using time shift of %d ms for %d feedback markers with missing optical markers', time_shift, length(i_unmatched_feedback))
        mrk_updated.time(i_unmatched_feedback) = mrk_updated.time(i_unmatched_feedback) + time_shift;
    end
    
    %add interactions
    mrk_updated = mrk_sortChronologically(mrk_mergeMarkers(mrk_updated, mrk_interactions));
    
    if nargout > 1
       display_delays = delays;
    end
    
    %inspect manually, e.g., with [mrk_orig.event.desc(1:20),mrk_orig.time(1:20)',mrk_timed.event.desc(1:20), mrk_timed.time(1:20)']
end

%References
% mrk_matchStimWithResp
% mrk_selectClasses
% mrk_defineClasses
% mrk_mergeMarkers