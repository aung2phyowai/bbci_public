function [  ] = init_experiment_setup( )
%INIT_EXPERIMENT_SETUP Initialize (local) setup for experiment
%   Delegates to ../common_util/project_setup.m

curDir = fileparts(which(mfilename));
commonUtilDir = fullfile(fileparts(curDir), 'common_util');
addpath(commonUtilDir);
project_setup();

global PROJECT_SETUP

addpath(PROJECT_SETUP.TCP_UDP_DIR);
addpath(genpath(fullfile(PROJECT_SETUP.EXPERIMENT_SCRIPTS_DIR, 'util')));
end

