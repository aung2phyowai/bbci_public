function [] = pyff_start_feedback_controller( )
%pyff_start_feedback_controller Start the FeedbackController process
global PROJECT_SETUP

%% kill existing feedback process in case it's still running
if isunix()
    system('pkill -9 -f "python FeedbackController.py"');
end

%% Start pyff in background

pyffStartupCmd = ['cd ' fullfile(PROJECT_SETUP.PYFF_DIR, 'src')...
    ' && python FeedbackController.py --nogui'...
    ' -a ' PROJECT_SETUP.FEEDBACKS_DIR ...
    '  --loglevel=info --fb-loglevel=debug'...
    ' 2> ' fullfile(PROJECT_SETUP.LOG_DIR, 'pyff.stderr.log')...
    ' 1> ' fullfile(PROJECT_SETUP.LOG_DIR, 'pyff.stdout.log')...
    '  &'];



fprintf('Opening FeedbackController...')
dynamicLibLookupPath = getenv('LD_LIBRARY_PATH');
setenv('LD_LIBRARY_PATH',getenv('PATH'));
system(pyffStartupCmd,'-echo');
setenv('LD_LIBRARY_PATH',dynamicLibLookupPath);
fprintf(' Done!\n')

%% Setup UDP connection with the feedback

fprintf('Initializing UDP connection...')
pyff_sendUdp('init',  PROJECT_SETUP.UDP_FEEDBACK_HOST, PROJECT_SETUP.UDP_FEEDBACK_PORT);
fprintf('Done!\n')
pause(0.1)

fprintf('Initializing feedback...')
pyff_sendUdp('interaction-signal', 's:_feedback', PROJECT_SETUP.FEEDBACK_NAME, 'command','sendinit');
fprintf(' Done!\n')

end

