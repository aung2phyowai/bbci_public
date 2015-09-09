function [] = init_analysis_setup(  )
%INIT_ANALYSIS_SETUP Initialize (local) setup for analysis
%   Delegates to ../common_util/project_setup.m
curDir = fileparts(which(mfilename));
commonUtilDir = fullfile(fileparts(curDir), 'common_util');
addpath(commonUtilDir);
project_setup();

global PROJECT_SETUP

addpath(fullfile(PROJECT_SETUP.ANALYSIS_SCRIPTS_DIR, 'util'));
end

