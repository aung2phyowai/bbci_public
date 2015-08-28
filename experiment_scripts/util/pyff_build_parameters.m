function fbsettings = pyff_build_parameters()
%PYFF_BUILD_PARAMETERS Builds feedback parameters based on
%EXPERIMENT_CONFIG

global PROJECT_SETUP
global EXPERIMENT_CONFIG

fbsettings = struct;

fbsettings.use_optomarker = EXPERIMENT_CONFIG.feedback.use_optomarker;
fbsettings.image_width = EXPERIMENT_CONFIG.feedback.image_size(1);
fbsettings.image_height = EXPERIMENT_CONFIG.feedback.image_size(2);
fbsettings.screen_width = PROJECT_SETUP.SCREEN_SIZE(1);
fbsettings.screen_height = PROJECT_SETUP.SCREEN_SIZE(2);
fbsettings.screen_position_x = PROJECT_SETUP.SCREEN_POSITION(1);
fbsettings.screen_position_y = PROJECT_SETUP.SCREEN_POSITION(2);

end

