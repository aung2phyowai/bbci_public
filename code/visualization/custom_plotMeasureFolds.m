function axes_h = custom_plotMeasureFolds(bar_data, varargin)
% custom_plotMeasureFolds(bar_data) visualizes a metric (e.g. correlation
% value) across CV folds for a variable number of components. (explanation:
% in SPoC-lambda there can be more than one component used for predicting
% the target variable)
% 
% author: Andreas Meinel
% July, 2015 

%% Default options
def_title = [];
def_barColors = {[1 0.5 0],[1 0 0],[0 0.5 1],[0 0 1]};
def_fontSize = 10;
def_lineWidth = 1.5;
def_metricName = 'EMD'; % 'Corr' or 'EMD'
def_case = 'test';
def_corrAll = '';
def_corr_pval = '';
def_showBarLabels = 1;
def_showLeg = 0;

p = inputParser;

addParamValue(p,'title',def_title);
addParamValue(p,'barColors',def_barColors);
addParamValue(p,'fontSize',def_fontSize);
addParamValue(p,'lineWidth',def_lineWidth);
addParamValue(p,'metricName',def_metricName);
addParamValue(p,'case',def_case);
addParamValue(p,'corrAll',def_corrAll);
addParamValue(p,'corr_pval',def_corr_pval);
addParamValue(p,'showBarLabels',def_showBarLabels);
addParamValue(p,'showLeg',def_showLeg);

parse(p,varargin{:})
options = p.Results;

axes_h = gca;
axes(axes_h);
set(gca,'FontSize',options.fontSize)

%% Bar plotting

N_comp = size(bar_data,2);

if strcmp(options.case,'train')
    barColors = options.barColors{1};
    barColor_reg = options.barColors{2};
else
    barColors = options.barColors{3};
    barColor_reg = options.barColors{4};
end

b = bar(bar_data,'grouped','FaceColor',barColors); hold on;

if options.showBarLabels
    % gap in y-direction from top of the bar
    ybuff = 0.15;
    for k=1:length(b)
        xdata = get(get(b(k),'Children'),'XData');
        ydata = get(get(b(k),'Children'),'YData');
        x = xdata(1,1)+(xdata(3,1)-xdata(1,1))/2;
        y = ydata(2,1)+ybuff;
        if N_comp == 1
            t = {'c 1'};
        else
            t = cell(N_comp,1);
            for jj=1:N_comp
                t{jj} = ['c ',num2str(jj)];
            end
            switch options.metricName
                case 'Corr'
                    t{end} = 'rg';
            end
        end
        t = [t{k}];
        text(x,y,t,'Color','k','HorizontalAlignment','left','Rotation',90,...
            'FontSize',8,'FontWeight','bold')
    end
end

switch options.metricName
    case 'Corr'
%         N_comp = size(bar_data,2);
        set(b(N_comp),'FaceColor',barColor_reg);
                
    case 'EMD'
%         N_comp = size(bar_data,2);
        if N_comp ==1
            set(b(N_comp),'FaceColor',barColor_reg);
        end
end

% display legend within the plots
if options.showLeg
    if N_comp == 1
        leg = legend('cp. 1','Location','NorthOutside');
        set(leg,'FontSize',4)
    else
        tmp = cell(N_comp,1);
        for jj=1:N_comp
            tmp{jj} = ['cp. ',num2str(jj)];
        end
        switch options.metricName
            case 'Corr'
                tmp{end} = 'reg';
        end
        leg = legend(tmp{:},'Location','North');
        set(leg,'FontSize',4, 'Box','off')
    end
end

if ~isempty(options.corrAll)
    corr_mean = options.corrAll;
    for i = 1:length(corr_mean)
        plot([0 size(bar_data,1)+1], [corr_mean(i) corr_mean(i)],'Color',barColor_reg,...
        'LineWidth',options.lineWidth) ;
    end
else
    corr_mean = mean(bar_data(:,end));
end

xlabel('Subfolds')
ylabel([options.metricName,'_{',options.case,'}'])

switch options.metricName
    case 'Corr'
        ylim([-0.5,1])
    case 'EMD'
        ylim([0,1.3*max(max(bar_data))])
end

if isempty(options.title)
    options.title = sprintf([options.metricName,'_{',options.case,...
        '}= %.2d'],corr_mean);
end
if ~isempty(options.corr_pval)
    options.title = strcat(options.title,sprintf(' p_{val}= %.4d', options.corr_pval));
end
title(options.title)


end
