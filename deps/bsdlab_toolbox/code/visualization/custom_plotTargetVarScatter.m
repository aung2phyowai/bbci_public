function axes_h = custom_plotTargetVarScatter(z_map, z_est, varargin)
% axes_h = custom_plotTargetVarTrials(z_map, z_est, varargin)
% Plots target variable and corresponding estimation across trials
% Input:
%       z_map: Vector. True target variables across trials
%       z_est: Vector. Estimated target variable across trials
%
% Output:
%       axes_h: scalar. id of the axes
%
% Sebastian Castano
% 8th Dec. 2014

%% Default options
def_ylabel = 'z_{est} (msec)';
def_xlabel = 'z (msec)';
def_markerSymbol = 'o';
def_markerSize = 50; % Size of the markers shown the raw estimation
def_denormalize = true; % Denormalize the estimate target variable
def_idxFolds = []; % vector. [nfolds, nsamples] Shading the area of the trials corresponding to each of the subplots
def_colormapFolds = @(x) summer(x); % Colormap for the shade areas of the subplots
def_fontSize = 10;
def_xLim = [];
def_showLegend = 0;
def_dirSave = '';
def_figSize = [300,300];
def_title = '';

p = inputParser;
addParamValue(p,'ylabel', def_ylabel);
addParamValue(p,'xlabel', def_xlabel);
addParamValue(p,'markerSymbol', def_markerSymbol);
addParamValue(p,'markerSize', def_markerSize);
addParamValue(p,'denormalize', def_denormalize);
addParamValue(p,'idxFolds',def_idxFolds);
addParamValue(p,'colormapFolds',def_colormapFolds);
addParamValue(p,'fontSize',def_fontSize);
addParamValue(p,'xLim',def_xLim);
addParamValue(p,'showLegend',def_showLegend);
addParamValue(p,'dirSave',def_dirSave);
addParamValue(p,'figSize', def_figSize);
addParamValue(p,'title', def_title);

parse(p,varargin{:});
options = p.Results;

%% De-normalize estimated variable
if options.denormalize
    z_aux = zscore(z_est);
    z_est = std(z_map)*z_aux + mean(z_map);
    corr_z = corr(z_map',z_est');
end

axes_h = gca;
ylim_vec = [0.95*min(z_map),1.05*max(z_map)];
set(gca,'FontSize',options.fontSize)
set(gcf, 'Position', [200 200 options.figSize])

%% Scatter plot the estimate for each subfold (if indices are available)

axes(axes_h);
if ~isempty(options.idxFolds)
    colors = options.colormapFolds(numel(options.idxFolds));
    for i = 1:numel(options.idxFolds)
        scatter(z_map(options.idxFolds{i}),z_est(options.idxFolds{i}),...
            options.markerSize,colors(i,:),options.markerSymbol,'fill','MarkerEdgeColor',[0 0 0]); hold on;
    end
else
    scatter(z_map,z_est,options.markerSize,'b','fill','MarkerEdgeColor',[0 0 0])
end
xlabel(options.xlabel)
ylabel(options.ylabel)

if isempty(options.xLim)
    xlim([min([z_est, z_map]) max([z_est, z_map])])
    ylim([min([z_est, z_map]) max([z_est, z_map])])
else 
    xlim(options.xLim)
    ylim(options.xLim)
end

if options.showLegend
%     legend(l,options.legend,'Location', 'NorthEast')
    legend show
end

if ~isempty(options.title)
    title(options.title)
end

box on
grid on
hold off

if ~isempty(options.dirSave)
    savepic(options.dirSave, 'pdf');
    close all
end
end