function status = startup_bsdlab()
% status = startup_bsdlab()
% Initializes paths of the toolbox
%
% 
%
% Additional Comments:
% 
% Juan S. Castaño C.
% 12th Nov 2014

dir = strcat(fileparts(which('startup_bsdlab')));
addpath(strcat(dir,'/processing'));
addpath(strcat(dir,'/parallel'));
addpath(strcat(dir,'/external_toolbox/gpml')); startup();
addpath(strcat(dir,'/external_toolbox'));
addpath(strcat(dir,'/utils'));
end
