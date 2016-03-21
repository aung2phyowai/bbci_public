function axes_h = custom_plotCorrFolds(corrTest, varargin)
%
% Sebastian Castano
% 9th Dec. 2014

%% Default options
def_corrTrain = []; % Include correlation for the training set if you want to plot this too
def_plotMean = true;
def_title = [];
def_barColors = {[1 0 0],[0 0 1]};
def_barWidth = [0.6, 0.3];
def_corrAll = []; % corr(z,z_est) as a measure for the overall correlation 
def_corr_pval = [];
def_corrLim = [-0.5 1];
def_fontSize = 10;
def_lineWidth = 1.5;

p = inputParser;
addParamValue(p,'corrTrain',def_corrTrain);
addParamValue(p,'plotMean',def_plotMean);
addParamValue(p,'title',def_title);
addParamValue(p,'barColors',def_barColors);
addParamValue(p,'barWidth',def_barWidth);
addParamValue(p,'corrAll',def_corrAll);
addParamValue(p,'corr_pval',def_corr_pval);
addParamValue(p,'corrLim',def_corrLim);
addParamValue(p,'fontSize',def_fontSize);
addParamValue(p,'lineWidth',def_lineWidth);

parse(p,varargin{:})
options = p.Results;

axes_h = gca;
axes(axes_h);
set(gca,'FontSize',options.fontSize)

%% Bar plotting
corrTest = corrTest(:); % Convert into column vector

if ~isempty(options.corrTrain)
    options.corrTrain = options.corrTrain(:);
    bar_data = [options.corrTrain, corrTest];
else
    bar_data = corrTest;
%     legend(leg_text)
end

if isempty(options.corrAll)
    corr_mean = mean(abs(bar_data));
else
    corr_mean = mean(options.corrTrain);
    corr_mean(2) = options.corrAll; 
end
    
for i = 1:size(bar_data,2)
    bar(bar_data(:,i),options.barWidth(i),'FaceColor',options.barColors{i}); hold on;
end

if options.plotMean
    
    for i = 1:length(corr_mean)
        plot([0 size(bar_data,1)+1], [corr_mean(i) corr_mean(i)],'Color',options.barColors{i},...
        'LineWidth',options.lineWidth) ;
    end
end

xlabel('Subfolds')
ylabel('Correlation')

ylim(options.corrLim)
if ~isempty(options.corrTrain)
    legend('Train','Test')
end

if isempty(options.title)
    if ~isempty(options.corrTrain)
        options.title = sprintf('r_{train}= %.2d r_{test}= %.2d',corr_mean(1), corr_mean(2));
    else
        options.title = sprintf('r_{test}= %.2d',corr_mean);
    end
    if ~isempty(options.corr_pval)
        options.title = strcat(options.title,sprintf(' p_{val}= %.4d', options.corr_pval));
    end
    
    title(options.title)
end



end

