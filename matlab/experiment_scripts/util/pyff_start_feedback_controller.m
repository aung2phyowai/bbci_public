function [] = pyff_start_feedback_controller( )
%pyff_start_feedback_controller Start the FeedbackController process
global PROJECT_SETUP
global EXPERIMENT_CONFIG

%% kill existing feedback process in case it's still running
if isunix()
    system('pkill -9 -f "python FeedbackController.py"');
end
if ispc()
   % don't know about anything more selective than just killing all cmds
   % ... so we better ask
   if (input('Press "y" to kill all cmd.exe processes...\n', 's') == 'y')
       system('taskkill /IM cmd.exe');
   end
end

%% Start pyff in background

if PROJECT_SETUP.HARDWARE_AVAILABLE
    parallelPortParam = ['--port=', PROJECT_SETUP.PARALLEL_PORT_ADDRESS];
else
    parallelPortParam = '';
end
if isunix()
    outRedirects = [...
        ' > ' fullfile(EXPERIMENT_CONFIG.feedbackLogDir, 'pyff.log')...
        ' 2>&1'];
    if ~exist(EXPERIMENT_CONFIG.feedbackLogDir, 'dir')
        mkdir(EXPERIMENT_CONFIG.feedbackLogDir)
    end
else
    outRedirects = '';
end
pyffStartupCmd = ['cd ' fullfile(PROJECT_SETUP.PYFF_DIR, 'src')...
    ' && python FeedbackController.py --nogui'...
    ' -a ' PROJECT_SETUP.FEEDBACKS_DIR ...
    '  --loglevel=info --fb-loglevel=debug'...
    ' ' parallelPortParam ...
    outRedirects '  &'];



fprintf('Opening FeedbackController...')
dynamicLibLookupPath = getenv('LD_LIBRARY_PATH');
setenv('LD_LIBRARY_PATH',getenv('PATH'));
system(pyffStartupCmd,'-echo');
setenv('LD_LIBRARY_PATH',dynamicLibLookupPath);
fprintf(' Done!\n')

%% Setup UDP connection with the feedback
pause(0.1)
fprintf('Initializing UDP connection...')
pyff_sendUdp('init',  PROJECT_SETUP.UDP_FEEDBACK_HOST, PROJECT_SETUP.UDP_FEEDBACK_PORT);
pause(0.2)
fprintf('Done!\n')

fprintf('Initializing feedback...')
pyff_sendUdp('interaction-signal', 's:_feedback', PROJECT_SETUP.FEEDBACK_NAME, 'command','sendinit');
pause(0.2)
fprintf(' Done!\n')

end

