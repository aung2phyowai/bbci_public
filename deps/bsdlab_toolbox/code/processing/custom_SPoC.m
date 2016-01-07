function output = custom_SPoC(cnt, mrk, z, fct, ival, band, save_name, varargin)
% function custom_SPoC(cnt, mrk, z, fct, ival, band, save_name, varargin)
% Runs the bandpower regression for a given set of time and frequency
% parameters and saves the resulting correlations, patterns etc. to a
% matlab file.
% Wrapper for bandpower_regression_with_SPoC.m
% Input:
%       cnt: continous EEG data, need to be preprocessed (filtered, cleaned
%       from artifacts)
%       mrk: marker file
%       z: target variable z
%       n_map: index of the current mapping function
%       fct: mapping function (e.g. linear, quadratic etc.)
%       ival: matrix containing the time interval
%       band: matrix containing the frequency band
%       save_name: directory for saving the results of this function
%
%
% Optional Inputs:
%       See default options below and use the pair keyword-value to change
%       these default parameters.
%       The opts struct is passed to bandpower_regression_with_SPoC() and
%       to proc_ssd()
%
% Author: Andreas Meinel, Nov 2014
% Forked for general usage: Sebastian Castano, Dec. 2014


%% Setup default options

def_applyBootstrap = false;
def_mapFuncName = 'lin';
def_saveResults = true;
def_perfMetricLabel = 'RT';

p = inputParser;
p.KeepUnmatched = 1;

addParamValue(p,'applyBootstrap',def_applyBootstrap);
addParamValue(p,'mapFuncName',def_mapFuncName);
addParamValue(p,'saveResults',def_saveResults);
addParamValue(p,'perfMetricLabel',def_perfMetricLabel);

parse(p,varargin{:})
options = p.Results;

opt_unmat = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)]; 
opt_unmat = reshape(opt_unmat',[1,size(opt_unmat,1)*size(opt_unmat,2)]);

output = struct();

% choose the corresponding time interval
z_mod = feval(fct,z);
output.z = z_mod;

opt = {'n_folds', 5, ...
    'do_bandpass', 1,...
    opt_unmat{:}};

output.opt_SPoC = opt;

[output.xval_corr, output.out] = bandpower_regression_with_SPoC(cnt, mrk, ival, band, z_mod, opt{:});

if options.applyBootstrap
    opt_bt = {opt_unmat{:}};
    output.opt_SPoC = opt_bt;
    [~, out] = bandpower_regression_with_SPoC(cnt, mrk, ival, band, z_mod, opt_bt);
    output.out.corr_distribution = out.corr_distribution;
end

% saving the parameters of the SPoC analysis
params = struct;
params.ival = ival;
params.band = band;
params.clab = cnt.clab;
if p.Unmatched.applySSD
    params.dimsSSD = p.Unmatched.dimsSSD;
else
    params.dimsSSD = [];
end
params.mfct = func2str(fct); % converting the function handle to a string saves memory!!!
params.mfctName = options.mapFuncName;
params.metricLabel = options.perfMetricLabel;
output.params = params;

if options.saveResults
    save([save_name],'output')
end

end
