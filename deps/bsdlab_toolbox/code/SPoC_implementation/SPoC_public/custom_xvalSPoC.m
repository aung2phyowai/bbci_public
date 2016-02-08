function [out] = custom_xvalSPoC(cnt, mrk, z, epo_ival, band, varargin)
% custom_xvalSPoC is a slim version of "bandpower_regression_with_SPoC" 
% with fewer options and less overhead. Note, that for the first few 
% components (given by nc), the target variable is reconstructed
% separately. 
%
% Usage:
%   out = custom_xvalSPoC(cnt, mrk, z, epo_ival, band)
%
% IN:
%   cnt        - continuous data struct in bbci toolbox format 
%   mrk        - marker struct in bbci toolbox format
%   epo_ival   - two-element vector with time points that mark t_start and
%                   t_end of epochs to be cut out from cnt via mrk
%   z          - target function, one value for each epoch
%   band       - the frequency band to use for bandpass filtering. 
%
% Optional IN:
%   doBandpass - if 1 (default) the cnt will be bandpass filtered. Else it
%                   will be assumed that is filtered already.
%   n_folds    - number of folds for chronological xvalidation
%   n_spoc_components - number of spoc components which are considered for
%               the estimation of the target variable
%   
% OUT:
%   out         - a struct containing all the results of the function. 

def_nc = 3;
def_n_folds = 5;
def_doBandpass = 0;
def_applyFilter = 0; 

p = inputParser;
p.KeepUnmatched = 1;

addParameter(p,'n_folds',def_n_folds);
addParameter(p,'doBandpass',def_doBandpass);
addParameter(p,'nc',def_nc);
addParameter(p,'applyFilter',def_applyFilter);

parse(p,varargin{:})
opt = p.Results;

out = struct;

nc = opt.nc;
n_folds = opt.n_folds;
n_epos = length(z);

% bandpass-filter the continuous data
if opt.doBandpass
    
    display('Highpass filtering...');
    [b,a] = butter(5, band(1)/cnt.fs*2, 'high');
    cnt_flt = proc_filtfilt(cnt, b, a);
    
    display('Lowpass filtering...');
    [b,a] = butter(5, band(2)/cnt_flt.fs*2, 'low');
    cnt = proc_filtfilt(cnt_flt, b, a);
    clear cnt_flt
end

% train SPoC on all data (overfitted version!)
epo = proc_segmentation(cnt, mrk, epo_ival);
[W_alldata, A_alldata, eig] = spoc(epo.x, z);

if opt.applyFilter
    out.cnt_spoc = proc_linearDerivation(cnt,W_alldata(:,1:nc));
end

% get indices for chron. cross-validation
[divTr, divTe] = sample_chronKFold(ones(1,n_epos), n_folds);
if n_folds == 1
    divTr = divTe;
end

% pre-allocation of variables
z_est = zeros(n_epos,nc);
W = cell(1,n_folds);
lambda = cell(1,n_folds);
A_train = cell(1,n_folds);
A_test = cell(1,n_folds);
corrTest = zeros(nc,n_folds);

%% cross-validation for SPoC
display('Start cross-validation...');

for f_idx = 1:n_folds
    
    display(['Fold ',num2str(f_idx)]);
    
    idx_train = divTr{1}{f_idx};
    idx_test = divTe{1}{f_idx};
    
    % split in train and test data according to the folds
    epo_train = proc_selectEpochs(epo, idx_train);
    epo_test = proc_selectEpochs(epo, idx_test);
    
    z_train = z(idx_train);
    
    % train SPoC on the training data
    [W_fold, A_fold, lambda_fold] = spoc(epo_train.x, z_train);
    
    W(f_idx) = {W_fold};
    A_train(f_idx) = {A_fold};
    lambda(f_idx) = {lambda_fold};
    
    % verify the test data subspace in sensor space
    Cxx_te = proc_getCxx(epo_test);
    A_test{f_idx} = Cxx_te * W_fold;
    
    % select first n_spoc_components components
    W_fold = W_fold(:,(1:nc));
    
    % apply SPoC filter upon test data
    epo_spoc_test = proc_linearDerivation(epo_test,W_fold);
    
    % compute variance/bandpower features
    epo_spoc_var = proc_variance(epo_spoc_test);
    fv_test = squeeze(epo_spoc_var.x);
    
    if nc ==1 
        fv_test = fv_test';
    end    
    % fold-wise correlation on test data 
    corrTest(:,f_idx) = corr(z(idx_test)',fv_test(1:nc,:)');
    
    % build prediction of whole data set based on test data 
    z_est(idx_test,:) = fv_test';
end

%% evaluate SPoC performance across whole data-set 

idx_tp = ismember(1:size(z,2),find(z>prctile(z,50)));
for jj = 1:nc
    
    % overall correlation for component jj
    [R_all, pval] = corr(z',z_est(:,jj));
    out.R_all(jj) = R_all;
    
    % AUC value measuring the separability
    [X,Y,T,AUC] = perfcurve(idx_tp, z_est(:,jj),true);
    out.aucValue(jj) = AUC;
end

%% create the output
out.W_alldata = W_alldata;
out.A_alldata = A_alldata;
out.W = W;
out.A = A_train;
out.A = A_test;
out.lambda = lambda;
out.z_est = z_est;
out.corrTest = corrTest;


