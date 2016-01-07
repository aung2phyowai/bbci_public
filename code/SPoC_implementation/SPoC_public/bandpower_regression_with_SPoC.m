function [xval_corr, out] = bandpower_regression_with_SPoC(cnt, mrk, epo_ival, band, z, varargin)
%
% [xval_corr, out] = bandpower_regression_with_SPoC(cnt, mrk, epo_ival, band, z, varargin)
%
% IN:
%   cnt        - data struct in bbci toolbox format, filtered or unfiltered
%   mrk        - marker struct in bbci toolbox format
%   epo_ival   - two-element vector with time points that mark t_start and
%                   t_end of epochs to be cut out from cnt via mrk
%   band       - matrix of size [n_bands, 2], with frequency band limits in
%                the rows. analysis will be performed for each band
%                separatly
%   z          - target function, one value for each epoch
%
% Optional IN:
%   do_bandpass - if 1 (default) the cnt will be bandpass filtered. Else it
%                   will be assumed that is filtered already.
%   do_SSD      - if 1 (default) an SSD decomposition is done before
%                   applying SPoC
%   dims_SSD    - number of SSD-channels that are chosen, the method
%                   returns as many filters as EEG-channels
%   n_folds     - number of folds for chronological xvalidation
%   use_log     - use log-variance (default) or only variance
%   n_components - Number of SPoC components. If empty (default), this number
%                is determined via nested cross-validation
%   filter_order - filter order used for bandpass filter (default 5)
%   n_bootstrap_iterations - number of iterations to boostrap correlation
%                               distribution
%   verbose     - 1 (default) means give some output, 0 means be silent
%
% OUT:
% xval_corr     - matrix of size [n_bands, n_folds]. contains the
%                   correlations for each band and xval-fold
%
% Optional OUT:
% out.reg_weights   - cell array of size [n_bands, n_folds].
%                       reg_weights{b,f}.w stores the regression weights
%                       for band b and fold f
% out.z_est         - estimated z. concatenated xval output for each band
% out.W_alldata     - matrix of size [n_bands, n_channels, n_channels],
%                       contains SPoC filters for each band (trained on all
%                       data!!! -> may change to average over folds...)
%                       Each column is a filter.
% out.A_alldata     - SPoC spatial patterns, same format as the filter
%                       matrix. Each column is a pattern.
% out.corr_distribution - matrix of size [n_bands, n_bootstrap_iterations],
%                           contains the correlation values for each
%                           bootstrap iteration. Corr values are averaged
%                           across folds in each bootrap iteration.
% out.n_components  - number of selected components per band
% out.test_idx      - vector. [n_folds n_testSamples].
%                           Indices of the test epochs in each of the subfolds
% out.A_train       - cell array containing the patterns of the each
%                           subfold calculated for the training data
% out.A_test        - cell array containing the patterns of the each
%                           subfold calculated for the test data
%
%
% 07/2012 sven.daehne@tu-berlin.de
% 10/2014 Andreas Meinel added SSD preprocessing
% 01/2015 Andreas Meinel added SSD within the CV scheme + Pattern plots on
% subfold level

% dir = strcat(fileparts(which('spoc')));
dir = strcat(fileparts(which('bandpower_regression_with_SPoC')));
addpath([dir,'/SPoC_private'])

% Define defaults
def_spocType = 'lambda'; % Or lambda r2 or mse
def_spocOpt = [];
def_nfolds = 5;
def_useLog = true;
def_doBandpass = false;
def_applySSD = false;
def_dimsSSD = 14;
def_filterOrder = 5;
def_spocNumOfComp = [];
def_bootstrapIterations = [];
def_verbose = true;
% remove fields from spec-struct to save memory ('history'-field might consist several MBs)
def_removeSpecFields = 0; 
def_getEMD = 0; 
def_getAUC = 0;
def_eigResidVar = '';

p = inputParser;
p.KeepUnmatched = 1;

addParameter(p,'spocType',def_spocType);
addParameter(p,'spoc_opt',def_spocOpt) ;
addParameter(p,'n_folds',def_nfolds);
addParameter(p,'use_log',def_useLog);
addParameter(p,'do_bandpass',def_doBandpass);
addParameter(p,'applySSD',def_applySSD);
addParameter(p,'dimsSSD',def_dimsSSD);
addParameter(p,'filter_order',def_filterOrder);
addParameter(p,'spocNumOfComp',def_spocNumOfComp);
addParameter(p,'n_bootstrap_iterations',def_bootstrapIterations);
addParameter(p,'verbose',def_verbose);
addParameter(p,'removeSpecFields',def_removeSpecFields);
addParameter(p,'getEMD',def_getEMD);
addParameter(p,'getAUC',def_getAUC);
addParameter(p,'eigResidVar',def_eigResidVar);

parse(p,varargin{:})

opt = p.Results;
% using the unmatched input arguments
opt_unmat = [fieldnames(p.Unmatched),struct2cell(p.Unmatched)]; 
opt_unmat = reshape(opt_unmat',[1,size(opt_unmat,1)*size(opt_unmat,2)]);

%% init variables

switch lower(opt.spocType)
    case 'lambda'
        opt.spoc_func = @spoc;
    case 'r2'
        opt.spoc_func = @spoc_r2;
    case 'mse'
        opt.spoc_func = @spoc_mse;
    otherwise
        error('Given SPoC type is unknown: %s', opt.spocType)
end

n_channels = size(cnt.x,2);
n_epos = length(mrk.time);
n_folds = opt.n_folds;

% normalize the target function
z = (z-mean(z))/std(z);
z = z(:)'; % make it a row vector

n_bands = size(band, 1);
xval_corr = zeros(n_bands, n_folds);
perf = struct;
xval_p = zeros(n_bands, n_folds);
EMD_train = cell(n_bands,n_folds);
EMD_test = cell(n_bands,n_folds);
corr_tr = zeros(n_bands, n_folds);
corrTrain = struct;
corrTrain.regr = zeros(1,n_folds);
corrTest = struct;
corrTest.regr = zeros(1,n_folds);
lin_regs = cell(n_bands, n_folds);
n_components = zeros(n_bands,1);
z_est = zeros(n_bands, n_epos);
z_esttr = zeros(n_bands, n_epos);
W_alldata = cell(1,n_bands);
A_alldata = cell(1,n_bands);
A_train = cell(n_bands, n_folds);
W_folds = cell(n_bands, n_folds);
A_test = cell(n_bands,n_folds);
eig = cell(n_bands,n_folds);
corr_all_data = cell(1,n_bands);
test_idxSet = cell(n_bands,n_folds);
spec_no_ssd = cell(n_bands,1);

if (opt.applySSD)
    W_ssd = cell(n_bands,n_folds);
    A_ssd = cell(n_bands,n_folds);
    A_te_ssd = cell(n_bands,n_folds);
    score_ssd = cell(n_bands,n_folds);
    spec_ssd_te = cell(n_bands,n_folds);
    spec_ssd_tr = cell(n_bands,n_folds);
end

if not(isempty(opt.n_bootstrap_iterations))
    corr_distribution = zeros(n_bands, opt.n_bootstrap_iterations);
else
    corr_distribution = [];
end

sc_opt = [];
sc_opt.scalePos = 'none';
sc_opt.crossSize = 1.5;
sc_opt.contour = 0;
sc_opt.interpolation = 'cubic';
sc_opt.extrapolateToZero = 1;
sc_opt.extrapolate = 1;

%% loop over bands
for b_idx=1:n_bands
    
    if opt.verbose
        fprintf(' Starting regression for band = [%d, %d] Hz\n', band(b_idx,1), band(b_idx,2))
    end
    
    % compute spectrum on the raw data for each frequency band
    opt_spec = struct;
    opt_spec.Scaling = 'db';
    spec = proc_spectrum(cnt, [1 45], opt_spec);
    %     spec = proc_selectChannels(spec, {'C3', 'Cz', 'C4', 'Fz', 'Pz'});
    if opt.removeSpecFields
        spec_red = rmfield(spec,'history');
        spec_red = rmfield(spec_red,'title');
        spec_red = rmfield(spec_red,'file');
        spec = spec_red;
        clear spec_red
    end
    spec_no_ssd{b_idx} = spec;
    
    
    %% filter the cnt (if necessary)
    if opt.do_bandpass
        
        [b,a] = butter(opt.filter_order, band(b_idx,1)/cnt.fs*2, 'high');
        cnt_flt = proc_filtfilt(cnt, b, a);
        [b,a] = butter(opt.filter_order, band(b_idx,2)/cnt.fs*2, 'low');
        cnt_flt = proc_filtfilt(cnt_flt, b, a);
          
        % d = fdesign.bandpass('N,Fp1,Fp2,Ast1,Ap,Ast2',...
        %     30,band(b_idx,1)/cnt.fs*2,...
        %     band(b_idx,2)/cnt.fs*2, 30, 1, 30);
        % Hd = design(d,'ellip');
        % % apply a second filter (flipped) to remove phase shifts
        % (same as filtfilt)
        % cnt_flt = cnt;
        % cnt_flt.x = filter(Hd,cnt.x);
        % cnt_flt.x = flipud(filter(Hd,flipud(cnt_flt.x)));

        clear cnt
    else
        cnt_flt = cnt;
    end
    %     figure, plot_spectrum(cnt_flt, [0,45]);
    
    epo = proc_segmentation(cnt_flt, mrk, epo_ival);
    
    if opt.applySSD
        
        % compute SSD filter on all data
        opt_ssd = {'band', band(b_idx,:), opt_unmat{:}};
        [epo_ssd, W, A, score, ~]= proc_ssd(epo, opt_ssd{:});
        W_ssd_all = W;
        
        ssd_channels = cell(1,opt.dimsSSD);
        for ic= 1:opt.dimsSSD
            ssd_channels{ic}= ['ssd' int2str(ic)];
        end
        
        % reduce the dimensionality of the training epochs
        epo_ssd = proc_selectChannels(epo_ssd, ssd_channels);
        
        
        if isempty(opt.spocNumOfComp)
            opt.spocNumOfComp = determine_number_of_components(epo_ssd, z, [], opt);
        end
        
        %% compute SPoC on all data (dimensionality reduced by SSD)
        [fv_alldata, W, corr_alldata, out] = train_SPoC_var_features(epo_ssd, z, [], opt);
        
        W_comb = W(:,:)'*W_ssd_all(:,1:opt.dimsSSD)';
            
        Cxxe = proc_getCxx(epo);
        % covariance matrices in the SPoC space
        Cspoc = W_comb*Cxxe*W_comb';
        A = Cxxe*W_comb';
        A_alldata{b_idx} = A/Cspoc;        
        
        W_alldata{b_idx} = W_comb;
        corr_all_data{b_idx} = corr_alldata;
        Cxxe = out.Cxxe;
        
    else % if just SPoC is applied
        
        if isempty(opt.spocNumOfComp)
            opt.spocNumOfComp = determine_number_of_components(epo, z, [], opt);
        end
        %% compute SPoC on all data without SSD preprocessing
        
        % estimate number of informative components according to EV
        % drop-off
        if isnumeric(opt.eigResidVar)
            [~,~,score] = spoc(epo.x, z);
%             score_mod = score/max(score);
%             opt.spocNumOfComp = find(score_mod>opt.eigCutOff,1,'last');
%             numComp = find(min(diff(score(1:10))));
%             if numComp > opt.eigCutOff
%                 numComp = opt.eigCutOff;
%             end

            % linearly detrending ev-spectrum, get squared residuum    
            N_max = 8;
            res = abs(detrend(score));
            crit_1 = find(res > opt.eigResidVar*std(res));
            crit_2 = 1:N_max;
            numComp = max(intersect(crit_1,crit_2));
            if isempty(numComp)
                numComp = 1;
            end
            opt.spocNumOfComp = numComp;           
        end
        
        [fv_alldata, W, ~, out] = train_SPoC_var_features(epo, z, [], opt);
        W_alldata{b_idx} = W;
        A_alldata{b_idx} = out.A;
        corr_all_data{b_idx} = out.r_values;
        Cxxe = out.Cxxe;
        
    end
    
    %% SPoC regression using (nested) cross-validation
    %warning off
    [divTr, divTe] = sample_chronKFold(ones(1,n_epos), n_folds);
    if n_folds == 1
        divTr = divTe;
    end
    %warning on
    nc_per_fold = zeros(1,n_folds);
    for f_idx=1:n_folds
        
        % split the data into training and test set
        train_idx = divTr{1}{f_idx};
        test_idx = divTe{1}{f_idx};
        test_idxSet{b_idx, f_idx} = test_idx;
        
        epo_tr = proc_selectEpochs(epo, train_idx);
        epo_te = proc_selectEpochs(epo, test_idx);
        
        %% SSD preprocessing on training data
        
        if opt.applySSD
            
            [epo_tr_ssd, W, A, score, ~]= proc_ssd(epo_tr, opt_ssd{:});
            
            % compute spectrum of SSD filtered training data
            spec_tr = proc_spectrum(epo_tr_ssd, [2 45], opt_spec);
            % spec_tr = proc_selectChannels(spec_tr, {'ssd1', 'ssd2', 'ssd4', 'ssd6', 'ssd9'});
            spec_ssd_tr{b_idx,f_idx} = spec_tr;
            
            if opt.removeSpecFields
            spec_red = rmfield(spec_ssd_tr,'history');
            spec_red = rmfield(spec_red,'title');
            spec_red = rmfield(spec_red,'file');
            spec_ssd_tr = spec_red;
            clear spec_red
            end
            
            % apply SSD filter on the test data and compute the spectrum
            epo_te_ssd = proc_linearDerivation(epo_te, W, 'prependix','ssd');
            spec_te = proc_spectrum(epo_te_ssd, [2 45], opt_spec);
            % spec_te = proc_selectChannels(spec_te, {'ssd1', 'ssd2', 'ssd4', 'ssd6', 'ssd9'});
            spec_ssd_te{b_idx,f_idx} = spec_te;
            
            if opt.removeSpecFields
                spec_red = rmfield(spec_ssd_te,'history');
                spec_red = rmfield(spec_red,'title');
                spec_red = rmfield(spec_red,'file');
                spec_ssd_te = spec_red;
                clear spec_red
            end
            
            clear spec_te spec_tr epo_te_ssd
            
            % save filter, pattern and eigenvalue score for this specific frequency band
            W_ssd{b_idx,f_idx} = W;
            A_ssd{b_idx,f_idx} = A;
            score_ssd{b_idx,f_idx} = score;
            
            %dimensionality reduction by choosing a fixed number of SSD-channels
            ssd_channels = cell(1,opt.dimsSSD);
            for ic= 1:opt.dimsSSD
                ssd_channels{ic}= ['ssd' int2str(ic)];
            end
            
            % reduce the dimensionality of the training epochs
            epo_tr_raw = epo_tr;
            epo_tr = proc_selectChannels(epo_tr_ssd, ssd_channels);
            
            clear epo_tr_ssd
            
        end
        
        %% Nested X-val to determine number of SPoC components
        if isempty(opt.spocNumOfComp)
            nc = determine_number_of_components(epo_tr, z(train_idx), Cxxe(:,:,train_idx), opt);
        else
            nc = opt.spocNumOfComp;
        end
        nc_per_fold(f_idx) = nc;              
      
        if f_idx==1
            corrTrain.single_comp = zeros(nc,n_folds);
            corrTest.single_comp = zeros(nc,n_folds);
            fvTest = zeros(n_epos, nc);
        end
        
        %% train and test SPoC
        
        % train SPoC and linear regression on SPoC-power features
        % Compute the filters W and the projected data fv_tr on the
        % training data.
        % fv_tr is already projected in the "SPoC space" however it is
        % still a multidimensional representation of the estimated target
        % variable
               
        [fv_tr, W, ~, out_tmp] = train_SPoC_var_features(epo_tr, z(train_idx), Cxxe(:,:,train_idx), opt);
        %         epo_spoc_tr = proc_linearDerivation(epo_tr, W(:,1:nc));
                    
        kappa = 0;    
        % Since fv_tr is a multidimensional representation of the estimate
        % variable, we train a linear model that best projects fv_tr into a
        % uni-dimensional space. reg contain such linear model
        reg = train_linReg(fv_tr(1:nc,:), z(train_idx), kappa);
        
        epo_te_raw = epo_te;
        
        if opt.applySSD
            
            % backprojection of test data to sensor space using SSD filter
            C_n_te = proc_getCnoise(epo_te, opt_ssd{:});
            A_te_ssd{b_idx,f_idx} = C_n_te * W_ssd{b_idx,f_idx}(:,1:opt.dimsSSD);
            
            % apply SSD filter on test data
            epo_te_ssd = proc_linearDerivation(epo_te, W_ssd{b_idx,f_idx},...
                'prependix','ssd');
            epo_te = proc_selectChannels(epo_te_ssd, ssd_channels);
            
        end
        
        % fv_te corresponds to the same description of fv_tr. However,
        % given that this is the test set, we should use the same
        % regression model calculated above
        [fv_te, ~] = project_to_SPoC_var_features(W(:,1:nc), epo_te, opt);
        
        
        %% backprojection of training and test data to the sensor space
        
        if opt.applySSD
                               
            % covariance matrices in the sensor space
            Cxx_tr = proc_getCxx(epo_tr_raw);
            Cxx_te = proc_getCxx(epo_te_raw);
            
%             Cspoc_tr = proc_getCxx(epo_spoc_tr);
%             Cspoc_te = proc_getCxx(epo_spoc_te);
                                  
            % linear combination of SSD and SPoC filters 
            W_comb = W(:,1:nc)'*W_ssd{b_idx,f_idx}(:,1:opt.dimsSSD)';
            
            % covariance matrices in the SPoC space
            Cspoc_tr = W_comb*Cxx_tr*W_comb';
            Cspoc_te = W_comb*Cxx_te*W_comb';
            
            % calculate pattern accoriding to Haufe et al. 2014 "On the
            % interpretation of weight vectors of linear models", Theorem 1
            A_tr = Cxx_tr*W_comb';
            A_train{b_idx,f_idx} = A_tr/Cspoc_tr;
            
            A_te = Cxx_te*W_comb';
            A_test{b_idx,f_idx} = A_te/Cspoc_te;                    
            
        else
            % project the SPoC data back to sensor space
            Cxx_te = proc_getCxx(epo_te);
            A_test{b_idx,f_idx} = Cxx_te * W;
            
            A_train{b_idx,f_idx} = out_tmp.A;
        end
        
        % calculate earth movers distance (similarity metric) of the test 
        % and training patterns for all components
        if opt.getEMD
%             nc_min = min(size(A_alldata{b_idx},2),size(A_test{b_idx, f_idx},2));
            for compIdx = 1:nc
                EMD_test{b_idx,f_idx}(:,compIdx) = custom_EMD(A_test{b_idx,f_idx}(:,compIdx),A_alldata{b_idx}(:,compIdx), cnt_flt.clab);
                EMD_train{b_idx,f_idx}(:,compIdx) = custom_EMD(A_train{b_idx,f_idx}(:,compIdx),A_alldata{b_idx}(:,compIdx), cnt_flt.clab);
            end
        else
            EMD_test{b_idx,f_idx} = [];
            EMD_train{b_idx,f_idx} = [];
        end
        
        % report on z_est for each selected SPoC component (according to
        % opt.eigCutOff threshold
        fvTest(test_idx,:) = fv_te';
                
        % regress z on test data (band power)
        if nc==1
            z_est(b_idx,test_idx) = fv_te;
        else
            z_est(b_idx,test_idx) = apply_separatingHyperplane(reg, fv_te);
        end
        
        if nc==1
            z_esttr(b_idx,train_idx) = fv_tr;
        else
            z_esttr(b_idx,train_idx) = apply_separatingHyperplane(reg,fv_tr(1:nc,:));
        end
              
        %% Reporting on correlation values
        
        % training data:
        % regression based correlation (if nc = 1, there is no regression
        % model applied)
        corrTrain(b_idx).regr(f_idx) = corr(z(train_idx)', z_esttr(b_idx,train_idx)' );
        corr_tr(b_idx,f_idx) = corrTrain(b_idx).regr(f_idx);
        % training correlation for every single SPoC component 
        corrTrain(b_idx).single_comp(:,f_idx) = out_tmp.r_values';
        
        % test data:
        % regression based correlation (uses the regression learned on
        % training data)        
        [xval_corr(b_idx, f_idx),xval_p(b_idx, f_idx)] = corr(z(test_idx)', z_est(b_idx,test_idx)');
        corrTest(b_idx).regr(f_idx) = xval_corr(b_idx, f_idx);
        % test correlation for every single SPoC component 
        corrTest(b_idx).single_comp(:,f_idx) = corr(z(test_idx)',fv_te(1:nc,:)');
        
        % saving the regression weights
        lin_regs{b_idx, f_idx} = reg;
        
        % collect stuff from this fold
        W_folds{b_idx,f_idx} = W;
        eig{b_idx,f_idx} = out_tmp.eig;
        
    end
    n_components(b_idx) = ceil(mean(nc_per_fold));
    
    %% calculate AUC-value relative to 50-percentiles of z-distribution
    % all z-values larger than 50-prctile value are true-positive labels
    if opt.getAUC
        % get the index of the true positives
        idx_tp = ismember(1:size(z,2),find(z>prctile(z,50)));
        [X,Y,T,AUC] = perfcurve(idx_tp, z_est(b_idx,:),true);
        perf.aucValue(b_idx) = AUC;
        perf.X(b_idx,:) = X';
        perf.Y(b_idx,:) = Y';
        perf.T(b_idx,:) = T';
    end
    
    if opt.getAUC && isnumeric(opt.eigResidVar)
        for jj = 1:nc
            [X,Y,T,AUC] = perfcurve(idx_tp, fvTest(:,jj),true);
            perf_sc.aucValue(jj) = AUC;
            perf_sc.X(:,jj) = X';
            perf_sc.Y(:,jj) = Y';
            perf_sc.T(:,jj) = T';
        end
    end
        
    
    %% bootstrap the correlation distribution
    
    if opt.n_bootstrap_iterations > 0
        tmp_opt = opt;
        tmp_opt.do_bandpass = 0;
        tmp_opt.spocNumOfComp = n_components(b_idx);
        tmp_opt.n_bootstrap_iterations = [];
        tmp_opt.verbose = 0;
        z_amps = [];
        if opt.verbose; fprintf(' Starting bootstrapping\n'); end;
        for it=1:opt.n_bootstrap_iterations
            if opt.verbose && mod(it, ceil(opt.n_bootstrap_iterations/10)) == 0
                fprintf('   bootstrap iteration %d/%d\n', it, opt.n_bootstrap_iterations);
            end
            [z_shuffled, z_amps] = random_phase_surrogate(z, 'z_amps', z_amps);
            [tmp_corrs, tmp_out]= bandpower_regression_with_SPoC(...
                cnt_flt, mrk, epo_ival, band(b_idx,:), z_shuffled, tmp_opt);
%             corr_distribution(b_idx, it) = mean(tmp_corrs);
            corr_distribution(b_idx, it) = corr(z_shuffled',tmp_out.z_est');
        end
        if opt.verbose; fprintf(' Done bootstrapping\n'); end;
    end
end

out = [];
out.reg_weights = lin_regs;
out.z_est = z_est;
out.W_alldata = W_alldata;
out.A_alldata = A_alldata;
out.fv_alldata = fv_alldata;
out.A_train = A_train;
out.W_folds = W_folds;
out.corr_all_data = corr_all_data;
out.corr_distribution = corr_distribution;
out.n_components = n_components;
out.corr_tr = corr_tr;
out.corrTrain = corrTrain;
out.corrTest = corrTest;
out.test_idx = test_idxSet;
out.A_test = A_test;
out.eig_spoc = eig;
out.spec_no_ssd = spec_no_ssd;
out.xval_p = xval_p;
out.EMD_train = EMD_train;
out.EMD_test = EMD_test;
out.perf = perf;
out.fvTest = fvTest;
out.perf_sc = perf_sc;

if opt.applySSD
    out.W_ssd = W_ssd;
    out.A_ssd = A_ssd;
    out.A_te_ssd = A_te_ssd;
    out.score_ssd = score_ssd;
    out.spec_ssd_te = spec_ssd_te;
    out.spec_ssd_tr = spec_ssd_tr;
else
    out.W_ssd = [];
    out.A_ssd = [];
    out.A_te_ssd = [];
    out.score_ssd = [];
    out.spec_ssd_te = [];
    out.spec_ssd_tr = [];
end

function nc = determine_number_of_components(epo, z, Cxxe, opt)
% Determine number of SPoC components using xvalidation
% For each fold, an extra dimension is added. When the correlation does not
% improve further, the "optimal" number of SPoC components has been reached
n_epos = size(epo.x,3);
n_folds = opt.n_folds;
[divTr, divTe] = sample_chronKFold(ones(1,n_epos), n_folds);
improving = true;
nc = 1;
nested_corrs = zeros(1,n_folds);
last_corrs = -inf;
while improving
    opt.spocNumOfComp = nc;
    for ff_idx=1:n_folds
        tr_idx = divTr{1}{ff_idx}; % nested train indices
        te_idx = divTe{1}{ff_idx}; % nested test indices
        % train SPoC and sort components according to maximum abs
        % correlation
        if ~isempty(Cxxe)
            Cxxe_iter = Cxxe(:,:,tr_idx);
        else
            Cxxe_iter = [];
        end
        [fv_tr, W] = train_SPoC_var_features(...
            proc_selectEpochs(epo, tr_idx),...
            z(tr_idx), Cxxe_iter, opt);
        % train linear regression with SPoC features using the best nc
        % components.
        reg = train_linReg(fv_tr(1:nc,:), z(tr_idx));
        % compute SPoC var-features of test data
        fv_te = project_to_SPoC_var_features(W(:,1:nc), ...
            proc_selectEpochs(epo, te_idx), opt);
        % regress z on test data
        z_est = apply_separatingHyperplane(reg, fv_te);
        % determine corr between estimated and true z
        nested_corrs(ff_idx) = corr(z(te_idx)', z_est');
    end
    improving = mean(nested_corrs) > last_corrs;
    last_corrs = mean(nested_corrs);
    nc = nc + 1;
end
nc = nc - 2;