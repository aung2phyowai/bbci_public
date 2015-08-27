function fbsettings = pyff_build_parameters()
%PYFF_BUILD_PARAMETERS Builds feedback parameters based on
%EXPERIMENT_CONFIG

global EXPERIMENT_CONFIG

fbsettings = struct;

fbsettings.use_optomarker = EXPERIMENT_CONFIG.feedback.use_optomarker;
fbsettings.image_width = EXPERIMENT_CONFIG.feedback.image_size(1);
fbsettings.image_height = EXPERIMENT_CONFIG.feedback.image_size(2);


end

