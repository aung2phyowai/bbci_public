function axes_h = custom_plotEigenvalueSpectrum(eig, varargin)
% custom_plotSubfoldPatterns - plots the eigenvalue spectrum 
% (e.g. of SSD or SPoC).
%
% Synopsis
%  axes_h = custom_plotFreqSpectrum(eig, varargin)
%
% Arguments: 
%   eig
%
% Returns:
%   axes_h: ???
%
% Note: 
%
% Andreas Meinel, December 2014

%% Default options
def_normalize = false;
def_showCutOff = false; %display the cut-off dimension
def_cutDim = 14; % component for the cut-off
def_showTitle = false;
def_titleLabel = '';
def_fontSize = 14;
def_xLabel = 'component #';
def_yLabel = 'eigenvalue';

p = inputParser;
addParamValue(p,'normalize', def_normalize);
addParamValue(p,'showCutOff', def_showCutOff);
addParamValue(p,'cutDim', def_cutDim);
addParamValue(p,'showTitle', def_showTitle);
addParamValue(p,'titleLabel', def_titleLabel);
addParamValue(p,'fontSize', def_fontSize);
addParamValue(p,'xLabel', def_xLabel);
addParamValue(p,'yLabel', def_yLabel);

parse(p,varargin{:});
options = p.Results;

%% Plot the eigenvalue spectrum

if options.normalize
    eig = eig/norm(eig);
end

axes_h = gca;
stem(eig)
if options.showCutOff
    hx1 = graph2d.constantline(options.cutDim, 'LineStyle','--','LineWidth',1,'Color',[1 0 0]);
    changedependvar(hx1,'x');
end
grid on
box on
set(gca,'FontSize',options.fontSize)
xlabel(options.xLabel);
ylabel(options.yLabel);
xlim([0 size(eig,1)])

if options.showTitle
    title(options.titleLabel)
end
        
end
