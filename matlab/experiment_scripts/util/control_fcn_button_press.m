function [ packet, state ] = control_fcn_button_press( cfy_out, state, event_info, varargin)
%CONTROL_FCN_BUTTON_PRESS Function called after button_pressed interaction
%marker is sent
% disp('cfy_out')
% disp(cfy_out)
% disp('state')
% disp(state)
% disp('event_info')
% disp(event_info)
% disp('other args')
% celldisp(varargin)
% disp(event_info.all_markers)
disp('button pressed, relaying to feedback')
packet = {'event' , 'button_pressed',...
    'trigger_overlay', 1,...
    'time', event_info.time,...
    'marker', event_info.desc};
state = 'state';

end

