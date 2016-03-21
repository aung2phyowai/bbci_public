function [epo_win] = proc_windowEpochs(epo, varargin)
% [epo_win] = proc_windowEpochs(epo, varargin)
%  Windows epoched segments using the window win_func (tukey window by default)
% 
% arguments:
%       epo: struct. Epoched data as returned by proc_segmentation
%
% optional:
%       win: function handle. handle of the function to generate the window
%       win_opts: cell array. arguments of the win function (except window
%       length, which is automatically calculated).
%
% returns:
%       epo_win: struct. windowed data
%
% example:
%       epo_win = proc_window(epo, @tukeywin, {0.75});
%
% Created by sebastian.castano@blbt.uni-freiburg.de
% 01.06.2015

def_windowFunction = @tukeywin;
def_windowOpts = {0.3};

p = inputParser;

addParameter(p,'win_func',def_windowFunction);
addParameter(p,'win_opts',def_windowOpts);

parse(p,varargin{:});
options = p.Results;

[Te, Nc, Ne] = size(epo.x);
win = options.win_func(Te, options.win_opts{:});
win = repmat(win,[1,Nc]);
win = repmat(win,[1,1,Ne]);
epo_win = epo;
epo_win.x = epo_win.x.*win;

end

