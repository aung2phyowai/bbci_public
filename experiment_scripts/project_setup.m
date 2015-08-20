function project_setup()

global PROJECT_SETUP

local_setup()

%% configuration

PROJECT_SETUP.logging.enabled = false;
PROJECT_SETUP.validation.show_validation_stats = false;

%%%%%%%%%%%%%%%%%%%%%%%
% from this point on, the configuration should [usually] not be changed


%% marker definitions

%user interactions
PROJECT_SETUP.markers.return_pressed = 1;
PROJECT_SETUP.markers.playback_paused_toggled = 2;

%events
PROJECT_SETUP.markers.child = 11;
PROJECT_SETUP.markers.cyclist = 12;
PROJECT_SETUP.markers.runner = 13;
PROJECT_SETUP.markers.generic_event = 19;

%event modifiers
PROJECT_SETUP.markers.hazard = 20;
PROJECT_SETUP.markers.highlighted = 21;
PROJECT_SETUP.markers.from_left = 22;
PROJECT_SETUP.markers.from_right = 23;

%generic
PROJECT_SETUP.markers.preload_completed = 40;
PROJECT_SETUP.markers.trial_start = 60;
PROJECT_SETUP.markers.trial_end = 65;
PROJECT_SETUP.markers.sync_50_frames = 50;
PROJECT_SETUP.markers.classifier_trigger = 80;


% feedback
PROJECT_SETUP.FEEDBACK_NAME = 'ImageSeqViewer';

PROJECT_SETUP.UDP_MARKER_PORT = 12344;
PROJECT_SETUP.UDP_FEEDBACK_HOST = 'localhost';
PROJECT_SETUP.UDP_FEEDBACK_PORT = 12345;


%% directories

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