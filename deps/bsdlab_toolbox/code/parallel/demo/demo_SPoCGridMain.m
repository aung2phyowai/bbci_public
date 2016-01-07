function demo_SPoCGridMain(VP)
% Example of a SPoC grid search in the computer cluster
%
% Only run this script in the bwUniCluster (in a computing node!, not in
% the login node)
%
% sebastian.castano@blbt.uni.freiburg.de
% 15. Dec. 2014
addpath(fullfile(getenv('HOME'),'source'));
set_localpaths();

%% Set paths
%Directory to store the processed data
dir_saveData = fullfile(getenv('HOME'),'posner_gridSearch','Data');

% Directory to the parameters of the study
dir_saveParameters = fullfile(getenv('HOME'),'posner_gridSearch','Parameters');

% Directory to store the results of the study
dir_saveResults = fullfile(getenv('HOME'),'posner_gridSearch','Results');
mkdir(dir_saveResults);

par = {VP,dir_saveData,dir_saveParameters,dir_saveResults};    
custom_parallelWrapSPoC(par{:});
 
