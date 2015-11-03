function [ output_args ] = pyff_stop_feedback_controller( input_args )
%PYFF_STOP_FEEDBACK_CONTROLLER Stops the currently running feedback and the
%feedback controller

pyff_sendUdp('interaction-signal', 'command','stop');


% close all feedback (controller processes)
pyff_sendUdp('interaction-signal', 'command','close');
pyff_sendUdp('interaction-signal', 'command','quitfeedbackcontroller');
pyff_sendUdp('close');


end

