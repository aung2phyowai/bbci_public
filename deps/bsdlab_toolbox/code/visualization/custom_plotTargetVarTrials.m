function axes_h = custom_plotTargetVarTrials(z_map, z_est, varargin)
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
def_fitCurve = true; % Requires toolbox gpml
def_ylabel = 'RT (ms)';
def_xlabel = 'Trial #';
def_legend = {'z','z_{est}'};
def_lineColor = {'r','b'}; % Color of the lines used to plot target variables
def_lineWidth = 2; % Width of the lines
def_markerSize = 1; % Size of the markers shown the raw estimation
def_denormalize = true; % Denormalize the estimate target variable
def_idxFolds = []; % vector. [nfolds, nsamples] Shading the area of the trials corresponding to each of the subplots
def_colormapFolds = @(x) summer(x); % Colormap for the shade areas of the subplots
def_yLim = '';

p = inputParser;
addParamValue(p,'fitCurve', def_fitCurve);
addParamValue(p,'ylabel', def_ylabel);
addParamValue(p,'xlabel', def_xlabel);
addParamValue(p,'legend', def_legend);
addParamValue(p,'lineColor', def_lineColor);
addParamValue(p,'lineWidth', def_lineWidth);
addParamValue(p,'markerSize', def_markerSize);
addParamValue(p,'denormalize', def_denormalize);
addParamValue(p,'idxFolds',def_idxFolds);
addParamValue(p,'colormapFolds',def_colormapFolds);
addParamValue(p,'yLim',def_yLim);

parse(p,varargin{:});
options = p.Results;

%% De-normalize estimated variable
if options.denormalize
    z_aux = zscore(z_est);
    z_est = std(z_map)*z_aux + mean(z_map);
    corr_z = corr(z_map',z_est');
end

axes_h = gca;
if isempty(options.yLim)
    ylim_vec = [0.95*min(z_map),1.05*max(z_map)];
else
    ylim_vec = options.yLim;
end
    
%% Create shading for each subfold
if ~isempty(options.idxFolds)    
    colors = options.colormapFolds(numel(options.idxFolds));
    for i = 1:numel(options.idxFolds)
        upper = repmat(ylim_vec(2),1,length(options.idxFolds{i}));
        lower = repmat(ylim_vec(1),1,length(options.idxFolds{i}));        
        color = colors(i,:);
        edgec = color;
        add = 1;
        transparency = 0.3;
        jbfill(options.idxFolds{i},upper,lower,color,edgec,add,transparency);
        
    end
end

%% Fit points with gaussian process regression and/or plot raw estimates
if options.fitCurve
    startup;
    x_all = [1:0.1:length(z_est)];
    x_train = [1:length(z_est)];
    hyp.mean =[0];
    hyp.cov = [1.5 1.5];
    hyp.lik = 1e-5;
    [z_estSmooth ys2 fmu fs2] = gp(hyp, @infExact, @meanConst, @covSEiso , @likGauss,x_train', z_est',  x_all');
    [z_smooth ys2 fmu fs2] = gp(hyp, @infExact, @meanConst, @covSEiso , @likGauss,x_train', z_map',  x_all');
    
    axes(axes_h); hold on
    l(1) = plot(x_all,z_smooth,'r','LineWidth',options.lineWidth);
    l(2) = plot(x_all,z_estSmooth,'b','LineWidth',options.lineWidth);
    plot(1:length(z_map),z_map,'r.',1:length(z_est),z_est,'b.','LineWidth',options.markerSize);
else
    axes(axes_h);
    plot(1:length(z_map),z_map,'r',1:length(z_est),z_est,'-*b','LineWidth',options.lineWidth)
end

xlabel(options.xlabel)
ylabel(options.ylabel)
box on
grid on
xlim([0 size(z_map,2)])
ylim(ylim_vec)
legend(l,options.legend{:},'Location', 'NorthEast')
hold off
end