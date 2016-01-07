function axes_h = custom_plotFreqSpectrum(spec, varargin)
% custom_plotFreqSpectrum - plots the spectra across the subfolds.
%
% Synopsis
%  axes_h = custom_plotFreqSpectrum(spec, band, varargin)
%
% Arguments: 
%   spec : struct containing the frequency spectrum
%   
% Returns:
%   axes_h: figure handle
%
% Note: 
%
% Andreas Meinel, December 2014

%% Default options
def_showFreqBand = true; %display the chosen frequency band
def_freqBand = [9, 11]; %specifiy the chosen frequency band
def_showTitle = false;
def_titleLabel = '';
def_fontSize = 14;
def_chLab = '';
def_showLeg = false; % show legend
def_legPos = [1 1 1 1]; % legend position [left bottom width height]
def_figSize = [300, 300];
def_dirSave = '';
def_yLim = '';
def_xLim = '';

p = inputParser;
addParamValue(p,'showFreqBand', def_showFreqBand);
addParamValue(p,'freqBand', def_freqBand);
addParamValue(p,'showTitle', def_showTitle);
addParamValue(p,'titleLabel', def_titleLabel);
addParamValue(p,'fontSize', def_fontSize);
addParamValue(p,'chLab', def_chLab);
addParamValue(p,'showLeg', def_showLeg);
addParamValue(p,'legPos', def_legPos);
addParamValue(p,'figSize', def_figSize);
addParamValue(p,'dirSave', def_dirSave);
addParamValue(p,'yLim', def_yLim);
addParamValue(p,'xLim', def_xLim);

parse(p,varargin{:});
options = p.Results;

%% Plot the spectral power as a function of the frequency

if ~isempty(options.chLab)
    spec = proc_selectChannels(spec, options.chLab);
end

axes_h = gca;
axes(axes_h);
set(gcf, 'Position', [200 200 options.figSize])

tmp = squeeze(mean(spec.x,3));
plot(spec.t, tmp,'Linewidth',2)
if options.showFreqBand
    hx1 = graph2d.constantline(options.freqBand(1), 'LineStyle','--','LineWidth',1,'Color',[0 0 0]);
    changedependvar(hx1,'x');
    hx2 = graph2d.constantline(options.freqBand(2), 'LineStyle','--','LineWidth',1,'Color',[0 0 0]);
    changedependvar(hx2,'x');
end
grid on
box on
set(gca,'FontSize',options.fontSize)
xlabel('frequency [Hz]');
ylabel('power [dB]');
if isempty(options.yLim)
    ylim([0.95*min(min(mean(spec.x,3))) 1.05*max(max(mean(spec.x,3)))])
else
    ylim(options.yLim)
end

if isempty(options.xLim)
    xlim([0 max(spec.t)])
else
    xlim(options.xLim)
end
    
if (options.showLeg)
    h = legend(spec.clab);
    newUnits = 'normalized';
    %     set(h,'PlotBoxAspectRatioMode','manual');
%     set(h,'PlotBoxAspectRatio',[0.1 0.1 0.1]);
    set(h,'Position',options.legPos,'Units',newUnits);
end

if options.showTitle
    title(options.titleLabel)
end

if ~isempty(options.dirSave)
    savepic(options.dirSave, 'pdf');
    close all
end
        
end
