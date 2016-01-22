clear, clc, close all;

%% Subject dependant variables
VPcode = 'VPtest';
date = '15_09_30';
VPcode = [VPcode '_' date];
prefix = 'posner_control_run';
patient = false;

%% Initialize paths

DUnit = pwd;
DUnit = DUnit(1);
addpath([DUnit ':\git\bbci_public']);
addpath(fullfile(pwd,'utils'))

set_localpaths();
startup_bbci_toolbox('DataDir', [DUnit ':\data\bbciRaw'],...
    'TmpDir', [DUnit ':\data\tmp'])

global dir_base
dir_base = [BTB.DataDir '\' VPcode '\'];
mkdir(dir_base);



%% Open feedbackcontroller - pyff
MatlabPath = getenv('LD_LIBRARY_PATH');
setenv('LD_LIBRARY_PATH',getenv('PATH'));
pyffdir = [DUnit ':\git\pyff\src'];
feedbackdir = [DUnit ':\git\posner\Feedbacks'];
disp('Opening FeedbackController')
if patient
    system(['cd ' pyffdir '&& python FeedbackController.py --nogui --port=0x4FF8 -a ' feedbackdir ' &'],'-echo');
else
    system(['cd ' pyffdir '&& python FeedbackController.py --nogui --port=0xD050 -a ' feedbackdir ' &'],'-echo');
end
setenv('LD_LIBRARY_PATH',MatlabPath);
pause(1)


%% Set udp connection for communication with feedback
bbci_feedback.host='localhost';
bbci_feedback.port=12345;

disp('Initializing UDP connection...')
pyff_sendUdp('init',  bbci_feedback.host, bbci_feedback.port);
pause(1)
disp('Done!')

% Start brain vision recorder
if patient
    system('c:\Vision\Recorder\Recorder\Recorder.exe &');
else
    system('c:\Vision\Recorder\Recorder.exe &');
end

disp('Opening bv recorder')
pause(3);


% iview_calibrate()

%% Set up bbci toolbox
bbci= struct;
bbci.source(1).acquire_fcn= @iview_acquire_gaze;
bbci.source(1).record_signals = true;
bbci.source(1).record_param = {'Internal' 1};


bbci.feature(1).ival = [-10 0];
if patient
    C = struct('b', 0, 'w', ones(370,1));
else
    C = struct('b', 0, 'w', ones(20,1));
end
bbci.classifier(1).feature = 1;
bbci.classifier(1).C = C;

bbci.quit_condition.marker = 127;
bbci.log.output = 0;


fbsettings = struct;
fbsettings.fullscreen = false;
% set pause interval
fbsettings.init_num_trials_before_global_pause = 4;
fbsettings.init_global_pause = 5000;
%%%% Timing %%%
fbsettings.init_cue_length = 2000;
fbsettings.cue_jitter = [0, 1000];
fbsettings.init_inter_trial_pause = 3000;
% stimulus settings
fbsettings.stimulus_height = 30;
fbsettings.stimulus_width = 30;
fbsettings.init_stimulus_length = 1000.0;
fbsettings.using_optoSensor = false;
if patient
    fbsettings.init_intervals = [0.05 0.06; 0.94 0.95];
    fbsettings.stimuli_count = [20,20];
    fbsettings.null_count = [1,1];
    fbsettings.false_count = [1,1];
    fbsettings.contrast_values = [10.0,10.0];
    
    fbsettings.screenSize = [1680 1050];
    fbsettings.screenPos = [-1680 0];
else
    fbsettings.init_intervals = [0.05 0.06; 0.05 0.06; 0.94 0.95; 0.94 0.95];
    fbsettings.stimuli_count = [10,10,10,10];
    fbsettings.null_count = [1,0,0,1];
    fbsettings.false_count = [0,1,1,0];
    fbsettings.contrast_values = [1.0,5.0,1.0,5.0];
end

new_contrast = 5;
fbsettings.contrast_values = [new_contrast,5, new_contrast,5];


block_name = [prefix num2str(1),'_'];
dir = [dir_base block_name];
bbci.source(1).record_basename = dir;

fbsettings.original_save_prefix = [dir 'log\'];
mkdir(fbsettings.original_save_prefix);


%new_limit = set_limit(fbsettings);
%fbsettings.init_intervals = [new_limit(1),new_limit(1)+0.01;...
%    new_limit(2)-0.01,new_limit(2)];

disp('Initializing feedback')
pyff_sendUdp('interaction-signal', 's:_feedback', 'Posner_Feedback', 'command','sendinit');

fbOpts = fieldnames(fbsettings);
for optId = 1:length(fbOpts),
    pyff_sendUdp('interaction-signal', fbOpts{optId}, getfield(fbsettings, fbOpts{optId}));
end
pause(1)
disp('Done!')

disp('Are you ready for the next block? Press any key.');
pause;
disp('Playing')
pyff_sendUdp('interaction-signal', 'command','play');
data= bbci_apply(bbci);
pyff_sendUdp('interaction-signal', 'command','stop');

disp('Done!, Press any key')
pause;
    
pyff_sendUdp('interaction-signal', 'command','close');
pyff_sendUdp('close');
disp('UDP connection succesfully closed')


