function [ output_args ] = pyff_send_utility_params( input_args )
%PYFF_SEND_UTILITY_PARAMS Summary of this function goes here

global EXPERIMENT_CONFIG

pyff_send_base_parameters()


fbsettings = EXPERIMENT_CONFIG.fb.reaction_time;

fbOpts = fieldnames(fbsettings);

fprintf('Sending feedback parameters:...\n')
fbsettings %#ok<NOPRT>
for optId = 1:length(fbOpts),
    pyff_sendUdp('interaction-signal', fbOpts{optId}, getfield(fbsettings, fbOpts{optId})); %#ok<GFLD>
    pause(0.1)
end
fprintf('... Done!\n')
end

