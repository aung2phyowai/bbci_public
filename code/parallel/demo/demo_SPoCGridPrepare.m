% Example of a SPoC grid search in the computer cluster
%
% Only run this script in the bwUniCluster (in a computing node!, not in
% the login node)
%
% sebastian.castano@blbt.uni.freiburg.de
% 15. Dec. 2014
close all; clear; clc;

addpath(fullfile(getenv('HOME'),'source'));
set_localpaths();

%% Set saving paths
%Directory to store the processed data
dir_saveData = fullfile(getenv('HOME'),'posner_gridSearch','Data');
mkdir(dir_saveData)

% Directory to store the parameters of the study
dir_saveParameters = fullfile(getenv('HOME'),'posner_gridSearch','Parameters');
mkdir(dir_saveParameters)

% %% Preprocess Data and save it
VPs = {'VPpaw_14_11_11','VPpay_14_11_27','VPpaz_14_12_04'};
runs = [3:18];

options_data ={'fs', 500,...
            'runsLoad', runs, ...
            'critMinMax',120, ...
            'sPosLim', [0 1920], ...
            'timeLim', [150 1000],...
            'ival', [-1000,0],...
            'classDef',{60;'stim'},...
            'notch', true,...
            'filter',[0.2 0.7 90 95],...
            'saveMatlab',1,...
            'loadMatlab',1};

for i = 1:numel(VPs)
        warning('No data preprocessed found for subject %s', VPs{i})
        [cnt_eeg, epo, mrk, rtrials] = custom_readPosnerOsciEEG(VPs{i}, options_data{:});
        rtrials = rtrials | isnan(epo.reactionTime);
        idx = find(~rtrials);
        epo = custom_selectEpochsPosner(epo,idx);
        mrk = mrk_selectEvents(mrk,idx);
        
        [epo_sorted mrk_sorted] = custom_sortPosnerContrast(epo,'mrk',mrk);
        epo = epo_sorted{2};
        mrk = mrk_sorted{2};
        
        z = epo.reactionTime;
        
        % Save processed data in matlab format
        clab = cnt_eeg.clab;
        save(fullfile(dir_saveData,VPs{i}),'cnt_eeg','mrk','z','rtrials','clab','runs','options_data')
end

%% Set parameters
% Frequency Bands
N_band = 40;
f0 = 1;
width_par = 2;
freq_spacing = width_par.^logspace(0,1/width_par,N_band);
fbands = [];
for n_band = 1:N_band
    f1 = f0+freq_spacing(n_band);
    fbands(n_band,:) = [f0, f1];
    f0 = f0 + freq_spacing(n_band)/2;
end

% Time intervals (prior to stimulus onset)
ival = [-1000, 0; -800, 0; -600, 0];

% Mapping Functions
map_names = {'linear'}; % This is just for the naming of the parameters' file
map_fcts = {@(x) x};

% SPoC options
opts = {'applySSD', 0 ,...
        'applyBootstrap', 0,...
        'spocType','r2',...
        'spocNumOfComp',1};
    
%% Pack parameters
for i = 1:size(ival,1)
    for j = 1:size(fbands,1)
        for k = 1:numel(map_fcts)
            args = {'ival',ival(i,:),...
                'fband', fbands(j,:),...
                'mapf', map_fcts{k}};
            ival_str = strjoin(strsplit(num2str(int32(ival(i,:)))),'-');
            fband_str =  strjoin(strsplit(num2str(fbands(j,:),'%.1f %.1f')),'-');
            par_name = ['/ival[' ival_str ']',...
                '_fband[' fband_str ']',...
                '_mapf-' map_names{k} '.mat'];
            par_name = fullfile(dir_saveParameters,par_name);
            save(par_name,'args','opts');
        end
    end
end
