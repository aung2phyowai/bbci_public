function axes_h = custom_plotMetricFolds(test, varargin)
% 
% adapted from custom_plotCorrFolds()
% Andreas Meinel
% June, 2015 

%% Default options
def_train = []; % Include correlation for the training set if you want to plot this too
def_plotMean = true;
def_title = [];
def_barColors = {[1 0 0],[0 0 1]};
def_barWidth = [0.6, 0.3];
def_fontSize = 10;
def_lineWidth = 1.5;
def_yLabel = 'EMD (a.u.)';

p = inputParser;
addParamValue(p,'train',def_train);
addParamValue(p,'plotMean',def_plotMean);
addParamValue(p,'title',def_title);
addParamValue(p,'barColors',def_barColors);
addParamValue(p,'barWidth',def_barWidth);
addParamValue(p,'fontSize',def_fontSize);
addParamValue(p,'lineWidth',def_lineWidth);
addParamValue(p,'yLabel',def_yLabel);

parse(p,varargin{:})
options = p.Results;

axes_h = gca;
axes(axes_h);
set(gca,'FontSize',options.fontSize)

%% Bar plotting
test = test(:); % Convert into column vector

if ~isempty(options.train)
    options.train = options.train(:);
    bar_data = [options.train, test];
else
    bar_data = test;
%     legend(leg_text)
end

if isempty(options.train)
    corr_mean = mean(bar_data);
else
    corr_mean = mean(options.train);
    corr_mean(2) = mean(test); 
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
ylabel(options.yLabel)

ylim([0,1.2*max([test',options.train'])])
if ~isempty(options.train)
    legend('Train','Test')
end

if isempty(options.title)
    if ~isempty(options.train)
        options.title = sprintf('EMD_{train}= %.2d EMD_{test}= %.2d',corr_mean(1), corr_mean(2));
    else
        options.title = sprintf('EMD_{test}= %.2d',corr_mean);
    end
        
    title(options.title)
end



end