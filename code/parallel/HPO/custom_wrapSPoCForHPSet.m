function [r2_test] = custom_wrapSPoCForHPSet(fctName, f_0, delta_f, ...
    t_0, delta_t, applySSD, dimsSSD, margin, peakWidthSSD, metricName,...
    varargin)
% function custom_wrapSPoCForHPSet()
% runs the bandpower_regression_with_SPoC() for a chosen hyperparameter
% set. Optionally, the results can be saved and visualized.
% Wrapper for custom_SPoC.m
% Input:
%       fctName: string that names the mapping function, e.g. 'x'      
%       f_0: lower frequency for the SPoC frequency band
%       delta_f: width of the SPoC frequency band
%       t_0: left boarder of the pre-trial interval (time in ms)
%       delta_t: width of the time interval (in ms)
%       applySSD: boolean for conditional SSD preprocessing
%       dimsSSD: dimension of the SSD preprocessing
%       margin: margin for the noise term in SSD
%       peakWidthSSD: width of the "signal" in the frequency domain
%       metricName: string that names the label information used for SPoC
%
% Optional Inputs:
%       See default options below and use the pair keyword-value to change
%       these default parameters.
%
% Author: Andreas Meinel, Jan 2015


%% Setup default options

def_doPlot = true; % do the plotting of the results
def_numOfComp = 1; % specifies the number of components
def_bestOfIdx = 0; % if the function is called to plot the best-of

p = inputParser;
p.KeepUnmatched = 1;

addParamValue(p,'doPlot',def_doPlot);
addParamValue(p,'numOfComp',def_numOfComp);
addParamValue(p,'bestOfIdx',def_bestOfIdx);

parse(p,varargin{:})
options = p.Results;
% opt_unmat = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)]; 
% opt_unmat = reshape(opt_unmat',[1,size(opt_unmat,1)*size(opt_unmat,2)]);

%% Loading the preprocessed EEG-data
% VP = 'VPpbc_15_01_15';
% VP = 'VPpblh_15_03_10';
VP = 'VPpbly_15_06_11';

% !!!customize this folder name!!! (the VP naming part can be skipped, 
% just specify the folder of "dataForHPsearch.mat"!)
dir_save = ['/home/andreas/projects/Hyperparameter_Optimization/version_3/dataMat/',VP,'/'];

date = '29-Jun-2015';

set_localpaths();
load([dir_save, 'EEGdataForHPsearch_',date,'.mat'],'cnt_eeg');
load([dir_save,'dataForHPsearch_',metricName,'_',date,'.mat'],'mrk','z')

mnt = mnt_setElectrodePositions(cnt_eeg.clab);

%% Setting up the parameters

% continuous parameters
ival = [t_0, t_0+delta_t];
band = [f_0, f_0+delta_f];
% fct = @(x) x;

switch fctName
    case 'x'
        fct = @(x) x;
    case 'x2'
        fct = @(x) x.^2;
    case 'x3'
        fct = @(x) x.^3;
    case 'log'
        fct = @(x) log(x);
    case 'lowpass'
        fct = @(x) smooth(x,8,'moving')';
    case 'highpass'
        fct = @(x) x-smooth(x,8,'moving')';
end

if options.bestOfIdx == 0
    dir_figures = [dir_save,'figures/'];
    mkdir(dir_figures); % creates the directory if it doesn't exist yet
else
    dir_figures = ['/home/andreas/projects/Hyperparameter_Optimization/version_2/results/',VP,'/'];
    mkdir(dir_figures);        
end

% dir_figures = [dir_save,'figures/'];
% mkdir(dir_figures); % creates the directory if it doesn't exist yet

opts = {'spocType','lambda', ...
    'spocNumOfComp', [],...
    'applySSD', applySSD, ...
    'dimsSSD', dimsSSD, ...
    'delta_f', peakWidthSSD, ...
    'stopBandMargin', [-margin, margin], ...
    'mapFuncName', fctName,...
    'saveResults', 0,...
    'getEMD', 1};      

%% Run the SPoC-optimization and plot results

try 
    output = custom_SPoC(cnt_eeg, mrk, z, fct, ival, band, dir_figures, opts{:});
        
    if options.doPlot
        for jj=1:options.numOfComp
            custom_plotSPoC(output, [dir_figures, 'BestOf-No1', num2str(options.bestOfIdx)],...
                'saveToFile', 1, 'figFlags', [1 1],'spocCompIdx', jj);
            if applySSD
                custom_plotSSD(output, [dir_figures, 'BestOf-No1', num2str(options.bestOfIdx)],...
                    'saveToFile', 1, 'figFlags', [1 1],'compIdx', jj);
            end
        end
    end
    
    xval_corr = output.xval_corr;
%     r2_test = mean(xval_corr.^2);
    r2_test = mean(xval_corr)^2; 

catch
    r2_test = NaN;
    
end

display(r2_test)

% exit

end