function [] = pyff_start_feedback_controller( )
%pyff_start_feedback_controller Start the FeedbackController process
global PROJECT_SETUP

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
pyffStartupCmd = ['cd ' fullfile(PROJECT_SETUP.PYFF_DIR, 'src')...
    ' && python FeedbackController.py --nogui'...
    ' -a ' PROJECT_SETUP.FEEDBACKS_DIR ...
    '  --loglevel=info --fb-loglevel=debug'...
    ' ' parallelPortParam ...
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
pause(0.1)
fprintf('Done!\n')

fprintf('Initializing feedback...')
pyff_sendUdp('interaction-signal', 's:_feedback', PROJECT_SETUP.FEEDBACK_NAME, 'command','sendinit');
fprintf(' Done!\n')

end

