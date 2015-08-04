function setup_visual_complexity()

global PROJECT_SETUP

local_setup()


PROJECT_SETUP.EXPERIMENT_SCRIPTS_DIR= fileparts(which(mfilename));
PROJECT_SETUP.BASE_DIR= fileparts(PROJECT_SETUP.EXPERIMENT_SCRIPTS_DIR);
PROJECT_SETUP.FEEDBACKS_DIR=fullfile(PROJECT_SETUP.BASE_DIR, 'feedbacks');
PROJECT_SETUP.SEQ_DATA_DIR=fullfile(PROJECT_SETUP.DATA_DIR, 'seqs');
PROJECT_SETUP.LOG_DIR=fullfile(PROJECT_SETUP.BASE_DIR, 'logs');


addpath(PROJECT_SETUP.TCP_UDP_DIR);
addpath(fullfile(PROJECT_SETUP.EXPERIMENT_SCRIPTS_DIR, 'util'))
addpath(PROJECT_SETUP.BBCI_DIR);

startup_bbci_toolbox(...
    'DataDir', PROJECT_SETUP.BBCI_DATA_DIR,...
    'TmpDir', PROJECT_SETUP.BBCI_TMP_DIR)

evalin('base', 'global PROJECT_SETUP');

PROJECT_SETUP %#ok<NOPRT>