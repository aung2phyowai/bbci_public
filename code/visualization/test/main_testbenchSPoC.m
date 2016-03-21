% Main script for the grid search (using mainStudy data)
%
% Sebastian Castano
% 2nd Dec. 2014
close all; clear; clc;
set_localpaths();

%% Set data load saving
%Directory to store the processed data
dir_saveData = fullfile(getenv('HOME'),'Desktop','tmp','Data');
mkdir(dir_saveData)

% Directory to store the results of the study
dir_saveResults = fullfile(getenv('HOME'),'Desktop','tmp','Results');
mkdir(dir_saveResults)

% VPs and runs to load
VPs = {'VPpay_14_11_27'};
runs = [3:5];

%% Compute results
set_spocPar;
load_data; %% Only Posner data!, change accordingly if wanna try something else
compute_spoc;

%% Load Results
clearvars -except VPs dir_saveResults dir_saveData

dir_resVP{1} = dir(fullfile(dir_saveResults,VPs{1}));

load(fullfile(dir_saveData,[VPs{1} 'parameters']),'runs','fbands','ival','map_fcts','do_SSD');
load(fullfile(dir_saveResults,VPs{1},dir_resVP{1}(3).name));
load(fullfile(dir_saveData,[VPs{1}]),'clab');

%% Plot target variable: Real and Estimated across trials
figure
z_map = output.z;
z_est = output.out.z_est;
idx_folds = output.out.test_idx;
axes_h = custom_plotTargetVarTrials(z_map, z_est, 'idxFolds',idx_folds);

%% Scatter plot target real vs Estimated
figure
z_map = output.z;
z_est = output.out.z_est;
idx_folds = output.out.test_idx;
axes_h = custom_plotTargetVarScatter(z_map, z_est, 'idxFolds',idx_folds);

%% Plot correlation across folds (bars)
figure
corrTest = output.xval_corr;
corrTrain = output.out.corr_tr;
axes_h = custom_plotCorrFolds(output.xval_corr,'corrTrain', corrTrain);