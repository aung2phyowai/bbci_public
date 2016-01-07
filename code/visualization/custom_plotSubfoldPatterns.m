function [axes_vec, h] = custom_plotSubfoldPatterns(A,mnt,varargin)
% custom_plotSubfoldPatterns - plots the patterns of A across the subfolds.
%
% Synopsis
%  axes_vec = custom_plotSubfoldPatterns(A,mnt,...)
%
% Arguments: 
%   A : cell array containing a mixing matrix for each subfold
%   mnt: electrode montage 
%
% Options:
%   colorbarLim = 'range', 'sym' (default), '0tomax', 'minto0',
%                   or [minVal maxVal]
%
% Returns:
%   axes_vec: struct containing two fields for each subfold
%
% Note: 
%
% Andreas Meinel, December 2014

%% Default options
def_showTitle = true;
def_titleLabel = 'Subfold '; 
def_colorbarLim = 'sym'; % color bar boarders 
def_figSize = [400 300];
def_colorbarPos = 'vert'; % colorbar placement 'horiz', 'vert' or 'none'
def_compIndex = 1; % choosing the index of the component to visualize

p = inputParser;
addParamValue(p,'showTitle', def_showTitle);
addParamValue(p,'titleLabel', def_titleLabel);
addParamValue(p,'colorbarLim', def_colorbarLim);
addParamValue(p,'figSize', def_figSize);
addParamValue(p,'colorbarPos', def_colorbarPos);
addParamValue(p,'compIndex', def_compIndex);

parse(p,varargin{:});
options = p.Results;

%% Create scalp plot of the first component for each subfold 

% Intializing variables
N_folds = size(A,2);
axes_vec = struct;

for f_idx = 1:N_folds
        
    h(f_idx) = figure('Units','pixels','visible','off',...
        'position',[0, 0, options.figSize]);
    [H, Ctour] = plot_scalp(mnt, A{f_idx}(:,options.compIndex), 'Extrapolation',1,'ExtrapolateToMean',1,...
        'ContourLineprop',{'LineWidth',0.2},'Resolution',200,'LineProperties',...
        {'LineWidth',2}, 'CLim', options.colorbarLim ,'TicksAtContourLevels',0,...
        'ScalePos',options.colorbarPos);
    set(gca, 'FontSize', 16);
    axes_vec(f_idx).H = H;
    axes_vec(f_idx).Ctour = Ctour;
    
    if options.showTitle
        title([options.titleLabel, num2str(f_idx)])
    end
    
end

        
end

