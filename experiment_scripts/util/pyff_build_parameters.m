function fbsettings = pyff_build_parameters()
%PYFF_BUILD_PARAMETERS Builds feedback parameters based on
%EXPERIMENT_CONFIG

global PROJECT_SETUP
global EXPERIMENT_CONFIG

fbsettings = struct;

fbsettings.param_logging_dir = fullfile(EXPERIMENT_CONFIG.recordDir, 'feedback_logs');
fbsettings.param_logging_prefix = EXPERIMENT_CONFIG.filePrefix;

fbsettings.use_optomarker = EXPERIMENT_CONFIG.feedback.use_optomarker;
fbsettings.screen_width = PROJECT_SETUP.SCREEN_SIZE(1);
fbsettings.screen_height = PROJECT_SETUP.SCREEN_SIZE(2);
fbsettings.screen_position_x = PROJECT_SETUP.SCREEN_POSITION(1);
fbsettings.screen_position_y = PROJECT_SETUP.SCREEN_POSITION(2);

end

