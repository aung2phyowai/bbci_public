function [ mrk_updated ] = vco_mrk_stimClassFromButton( mrk_base, used_config, accepted_interval )

    stimuli_marker_codes = struct2array(used_config.markers.stimuli);
    
    reaction_marker_codes = [used_config.markers.interactions.button_pressed];
    
    %stimulus
    mrk_stimulus_markers = mrk_defineClasses(mrk_base,...
        {stimuli_marker_codes; 'stimulus_markers'},...
        'KeepAllMarkers', 0);
    mrk_response_markers = mrk_defineClasses(mrk_base,...
        {reaction_marker_codes; 'response_markers'},...
        'KeepAllMarkers', 0);

    
    [mrk_button_matched, i_matched_stim, i_matched_reaction] = mrk_matchStimWithResp(...
        mrk_stimulus_markers, mrk_response_markers,...
        'MaxLatency', accepted_interval(2),...
        'MinLatency', accepted_interval(1),...
        'AllowOvershoot', 1);%,...
%         'MissingresponsePolicy', 'accept')

    if size(i_matched_stim, 2) ~= size(i_matched_reaction, 2)
       error('matching failed with different numbers of feedback and optical markers')
    end
    if size(mrk_button_matched.time, 2) ~= size(mrk_stimulus_markers.time, 2)
        i_stim_missing_for_reaction = ~ismember(1:size(mrk_response_markers.time, 2), i_matched_reaction);
        warning(['found ' num2str(size(mrk_button_matched.time, 2)) ' matches with button press markers for '...
            num2str(size(mrk_stimulus_markers.time, 2)) ' feedback markers;'...
            ' stimuli missing for markers ' strcat(num2str(mrk_response_markers.event.desc(i_stim_missing_for_reaction)'))...
            ' at time ' strcat(num2str(mrk_response_markers.time(i_stim_missing_for_reaction)))])
    end
    
    %just to add second class to the marker structure
    mrk_stimulus_classes = mrk_defineClasses(mrk_stimulus_markers,...
        {[], struct2array(used_config.markers.interactions);
        'press', 'no_press'},...
        'KeepAllMarkers', 1);
    mrk_stimulus_classes.y(1, :) = 1; %mark all as no_press
    mrk_stimulus_classes.y(1,i_matched_stim) = 0;
    mrk_stimulus_classes.y(2,i_matched_stim) = 1;
    
    %add interactions
    mrk_updated = mrk_sortChronologically(mrk_stimulus_classes);
    
    
    %inspect manually, e.g., with [mrk_orig.event.desc(1:20),mrk_orig.time(1:20)',mrk_timed.event.desc(1:20), mrk_timed.time(1:20)']
end

%References
% mrk_matchStimWithResp
% mrk_selectClasses
% mrk_defineClasses
% mrk_mergeMarkers