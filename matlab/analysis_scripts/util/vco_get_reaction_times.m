function [ reaction_times, jitter, exgaussian_params ] = vco_get_reaction_times( rt_mrk_timed, used_config )
%VCO_GET_REACTION_TIMES Extracts the reaction time from the marker
%structure
%   This function rejects reaction times that are 
%     - less than 100ms after the actual display of the stimulus
%     - after the display time in the feedback (exp_config.fb.reaction_time.max_reaction_time)
%
%   Be aware that the time should be corrected based on the optical markers
%   before calling this function

global PROJECT_SETUP

start_marker = used_config.markers.technical.seq_start;
stim_marker = used_config.markers.stimuli.generic_stimulus;
resp_marker = used_config.markers.interactions.button_pressed;

mrk_start = mrk_defineClasses(rt_mrk_timed,...
        {start_marker; 'start_markers'},...
        'KeepAllMarkers', 0);

mrk_stim = mrk_defineClasses(rt_mrk_timed,...
        {stim_marker; 'stim_markers'},...
        'KeepAllMarkers', 0);
    
mrk_resp = mrk_defineClasses(rt_mrk_timed,...
        {resp_marker; 'resp_markers'},...
        'KeepAllMarkers', 0);    


[~, i_matched_stim, i_matched_resp] = mrk_matchStimWithResp(...
        mrk_stim, mrk_resp,...
        'MaxLatency', used_config.fb.reaction_time.max_reaction_time * 1000,... %config values is in seconds
        'MinLatency', 100,...
        'AllowOvershoot', 0);%,...
%         'MissingresponsePolicy', 'accept')

reaction_times = mrk_resp.time(i_matched_resp) - mrk_stim.time(i_matched_stim);

[~, i_matched2_start, i_matched2_stim] = mrk_matchStimWithResp(...
        mrk_start, mrk_stim,...
        'MaxLatency', inf,... 
        'MinLatency', 0,... 
        'AllowOvershoot', 0);

stim_jitter_tmp = nan(size(mrk_stim.time));
stim_jitter_tmp(i_matched2_stim) = mrk_stim.time(i_matched2_stim) - mrk_start.time(i_matched2_start);
jitter = nan(size(reaction_times));
jitter(i_matched_stim) = stim_jitter_tmp(i_matched_stim);

%% estimate parameters of Exponentially modified Gaussian
if nargout > 2
    exgaussian_toolbox_path = fullfile(PROJECT_SETUP.MATLAB_LIB_DIR, 'exgaussian_tools');
    addpath(exgaussian_toolbox_path);
    exgaussian_params = struct;
    
    
    exgfit = egfit(reaction_times);
    exgaussian_params.mu = exgfit(1);
    exgaussian_params.sigma = exgfit(2);
    exgaussian_params.tau = exgfit(3);
    
    rmpath(exgaussian_toolbox_path);
end


end

