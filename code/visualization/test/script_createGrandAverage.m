
%% load data of all subjects, compute the grand average, plot it and save it
% 
% requires:     dir_saveResults - the path to store the resulting ga struct
%               
%               dir_saveMetrics - the path to the stored metrics (mrk,z)
%               dir_saveData - the path to the stored data (cnt_eeg);
%
%               performanceMetrics - a cell array of performance metrics
%               VPs - a cell array of VPs

percentile = 30;
gas = {};
cnts = {};
ival = [-200,1500];
for j = 1:numel(performanceMetrics)
    erps = {};
    metricName = performanceMetrics{j};
    if(shiftByRT)
        dir_saveGA = fullfile(dir_saveResults,'GA','shiftRT',metricName);
    else
        dir_saveGA = fullfile(dir_saveResults,'GA',metricName);
    end
    
    for i = 1:numel(VPs)
        
        vp = VPs{i};  
        if(shiftByRT)
            dir_Metrics = fullfile(dir_saveMetrics,'shiftRT',vp,metricName);
            dir_Data = fullfile(dir_saveData,'shiftRT',vp);
        else
            dir_Metrics = fullfile(dir_saveMetrics,vp,metricName);
            dir_Data = fullfile(dir_saveData,vp);
        end
        
        load([dir_Metrics,'.mat']);
        %load data only once
        if(j == 1)
            load([dir_Data,'.mat'],'cnt_eeg');
            cnts = {cnts{:},cnt_eeg};
        end
       
        cnt_eeg = cnts{i};
        epo = proc_segmentation(cnt_eeg,mrk,ival);
        epo = proc_baseline(epo,ival);
        epo_class = custom_sortSviptEpochs(epo,z,'FastSlow','prctile',percentile,'classLabels',{['low ',metricName],['high ',metricName]});
        epo_class.N = length(epo_class.y(1,:));
        erps = {erps{:},epo_class};
    end
    
    %expects a field 'prctile' in each epo 
    ga = custom_grandAverage(erps,'MustBeEqual',{'fs','className','prctile'},'Average','Nweighted');
    gas = {gas{:},ga};
   
    %% plot the ga
    mnt = mnt_setElectrodePositions(ga.clab);
    plot_ival = [0,125;....
        125,250;....
        250,375;....
        375,500;....
        500,625;....
        625,750;....
        750,875;....
        875,1000;....
        1000,1250;....
        1250,1500];
    
    figh = figure('Units','points','position',[200, 200, 550,450]);
    plot_scalpEvolutionPlusChannel(ga,mnt,{'Cz'},plot_ival);
    
    class_1 = find(ga.y(1,:) == 1);
    class_2 = find(ga.y(2,:) == 1);
    
    percentile = ga.prctile;
    suptitle(['Grand Average for High/low ',metricName,' ',num2str(percentile),'% perc split after go cue; N= ',num2str(length(class_1)),'/',num2str(length(class_2)),' trials']);
    
    if saveFigures
        %fband_str =  strjoin(strsplit(num2str(opts_eeg.filter,'%.0f %.0f')),'-');
        ival_str = strjoin(strsplit(num2str(int32(ival))),'-');
        %fband_str(fband_str == '.') = 'p';
        savepic([dir_saveFigures,'/','scalp_Evolution_GA',metricName,'_', ...
            'ival[',ival_str ,']'],figh, 'pdf');
        %save nonpdf
        saveas(figh,[dir_saveFigures,'/','scalp_Evolution_',metricName,'_', ...
            'ival[',ival_str ,']'],'fig');
        close all
    end
end


