function [] = init_analysis_setup(  )
%INIT_ANALYSIS_SETUP Initialize (local) setup for analysis
%   Delegates to ../common_util/project_setup.m
curDir = fileparts(which(mfilename));
addpath(curDir)
commonUtilDir = fullfile(fileparts(curDir), 'common_util');
addpath(commonUtilDir);
project_setup();

global PROJECT_SETUP

bsdlab_code_dir = fullfile(PROJECT_SETUP.BSDLAB_TOOLBOX_DIR, 'code');
addpath(bsdlab_code_dir)
startup_bsdlab()
%should actually be done by startup_bsdlab!?
addpath(genpath(fullfile(bsdlab_code_dir, 'visualization')));

addpath(fullfile(PROJECT_SETUP.ANALYSIS_SCRIPTS_DIR, 'util'));
end

