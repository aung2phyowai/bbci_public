function project_setup()

global PROJECT_SETUP


%% feedback


PROJECT_SETUP.UDP_MARKER_PORT = 12344;
PROJECT_SETUP.UDP_FEEDBACK_HOST = 'localhost';
PROJECT_SETUP.UDP_FEEDBACK_PORT = 12345;


%% directories


PROJECT_SETUP.COMMON_UTIL_DIR = fileparts(which(mfilename));
PROJECT_SETUP.MATLAB_DIR = fileparts(PROJECT_SETUP.COMMON_UTIL_DIR);
PROJECT_SETUP.BASE_DIR=fileparts(PROJECT_SETUP.MATLAB_DIR);

PROJECT_SETUP.EXPERIMENT_SCRIPTS_DIR= fullfile(PROJECT_SETUP.MATLAB_DIR, 'experiment_scripts');
PROJECT_SETUP.ANALYSIS_SCRIPTS_DIR= fullfile(PROJECT_SETUP.MATLAB_DIR, 'analysis_scripts');
PROJECT_SETUP.CONFIG_DIR= fullfile(PROJECT_SETUP.BASE_DIR, 'config');
PROJECT_SETUP.FEEDBACKS_DIR=fullfile(PROJECT_SETUP.BASE_DIR, 'feedbacks');

%for local setup
addpath(PROJECT_SETUP.CONFIG_DIR)
local_setup()

% dependencies
PROJECT_SETUP.DEPENDENCY_DIR=fullfile(PROJECT_SETUP.BASE_DIR, 'deps');

PROJECT_SETUP.BBCI_DIR = fullfile(PROJECT_SETUP.DEPENDENCY_DIR, 'bbci_public');
PROJECT_SETUP.BSDLAB_TOOLBOX_DIR = fullfile(PROJECT_SETUP.DEPENDENCY_DIR, 'bsdlab_toolbox');
PROJECT_SETUP.PYFF_DIR = fullfile(PROJECT_SETUP.DEPENDENCY_DIR, 'pyff');
PROJECT_SETUP.IVIEW_DIR = fullfile(PROJECT_SETUP.DEPENDENCY_DIR, 'iview');

%common_util should be already added
addpath(PROJECT_SETUP.BBCI_DIR);
addpath(fullfile(PROJECT_SETUP.MATLAB_DIR, 'lib'));

startup_bbci_toolbox(...
    'DataDir', PROJECT_SETUP.BBCI_DATA_DIR,...
    'TmpDir', PROJECT_SETUP.BBCI_TMP_DIR)

evalin('base', 'global PROJECT_SETUP');

PROJECT_SETUP %#ok<NOPRT>