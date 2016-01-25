function [ ] = pyff_send_base_parameters(  )
%PYFF_SEND_BASE_PARAMETERS Sends base parameters relevant for all feedbacks
%to the feedback controller
%   Information is taken from the PROJECT_SETUP and EXPERIMENT_CONFIG
%   structs

global PROJECT_SETUP
global EXPERIMENT_CONFIG

if ~exist(EXPERIMENT_CONFIG.feedbackLogDir, 'dir')
    mkdir(EXPERIMENT_CONFIG.feedbackLogDir)
end


fbsettings = struct;
fbsettings.optomarker_enabled = EXPERIMENT_CONFIG.fb.img_seq.use_optomarker;
fbsettings.screen_width = PROJECT_SETUP.SCREEN_SIZE(1);
fbsettings.screen_height = PROJECT_SETUP.SCREEN_SIZE(2);
fbsettings.screen_position_x = PROJECT_SETUP.SCREEN_POSITION(1);
fbsettings.screen_position_y = PROJECT_SETUP.SCREEN_POSITION(2);
fbsettings.display_debug_information = EXPERIMENT_CONFIG.fb.show_debug_infos;

fbsettings.log_dir = EXPERIMENT_CONFIG.feedbackLogDir;
fbsettings.log_prefix = EXPERIMENT_CONFIG.filePrefix;


fbOpts = fieldnames(fbsettings);

fprintf('Sending base feedback parameters:...\n')
fbsettings %#ok<NOPRT>
for optId = 1:length(fbOpts),
    pyff_sendUdp('interaction-signal', fbOpts{optId}, getfield(fbsettings, fbOpts{optId})); %#ok<GFLD>
    pause(0.1)
end
fprintf('... Done!\n')
end


