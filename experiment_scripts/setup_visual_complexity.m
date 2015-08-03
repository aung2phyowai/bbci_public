function setup_visual_complexity()

global PROJECT_SETUP

local_setup()

addpath(PROJECT_SETUP.BBCI_DIR);
addpath(PROJECT_SETUP.TCP_UDP_DIR);
startup_bbci_toolbox(...
    'DataDir', PROJECT_SETUP.BBCI_DATA_DIR,...
    'TmpDir', PROJECT_SETUP.BBCI_TMP_DIR)
PROJECT_SETUP.EXPERIMENT_SCRIPTS_DIR= fileparts(which(mfilename));
PROJECT_SETUP.BASE_DIR= fileparts(PROJECT_SETUP.EXPERIMENT_SCRIPTS_DIR);
PROJECT_SETUP.FEEDBACKS_DIR=fullfile(PROJECT_SETUP.BASE_DIR, 'feedbacks');
PROJECT_SETUP.LOG_DIR=fullfile(PROJECT_SETUP.BASE_DIR, 'logs')

evalin('base', 'global PROJECT_SETUP');