function results = simulations_SPoCExt(varargin)
% Executes a benchmarking experiment for accessing the performance of a
% spatio temporal filter in a regression task
% Returns performance
%
% 1) correlation values
% 2) Earth mover's distance between the simulated and estimated scalp pattern
%       (only for linear methods)
% 
% Created by Sven Daehne 2015
%
% Modified by Sebastian Castano. May 2015
% sebastian.castano@blbt.uni-freiburg.de

set_localpaths();
addpath('./utils')
addpath('./train')
addpath('./apply')

params = propertylist2struct(varargin{:});

%% parameter settings
params = set_defaults(params ...
    ,'n_components', 1 ...
    ,'n_cortical_noise_sources', 40 ...
    ,'n_train_epos', 240 ...250 ...250 ...%[100, 250, 500, 1000] ...
    ,'n_test_epos', 360 ...600 ...250 ...%[100, 250, 500, 1000] ...
    ,'SNR', 0.95 ...%[0.01, 0.05, 0.1, 0.5, 1, 1.5, 5] ...
    ,'ratio_sn_to_cn', 0.05 ...
    ,'rho_th', 1 ...
    ,'n_repetitions',2 ...
    ,'result_path', [] ...
    ,'epoch_length', 500 ... % in milliseconds
    ,'fs', 200 ...
    ,'frequency_band', [8,12] ... % freq band of the source
    ,'amplitude_minimum', 0.01 ...
    ,'amplitude_modulation_cutoff', 0.25 ...
    ,'amplitude_modulation_cutoff_bs', 0.25 ...
    ,'plot',1 ...
    ,'fir_order', 40 ... % order of the fir filter used by e.g. Oracle SPoC
    );

params

% List of methods to compare and corresponding properties
% name, training function, apply function, arguments of train and apply,
% function to compute the patterns from the filters
% Take a look at the train_SPoC/apply_SPoC examples to see what such
% function should look like
method_info = {
    {' Oracle SPoC', @train_SPoC, @apply_SPoC, struct('fs',params.fs,...
                                        'fband', [],...
                                        'N_filt', params.fir_order ), @getpatt_SPoC}                                        
	{' Oracle PCA', @train_PCA, @apply_SPoC, struct('fs',params.fs,...
                                        'fband', [],...
                                        'N_filt', params.fir_order ), @getpatt_SPoC}
};


% load pattern matrix
pat = load('patterns.mat');
clab = pat.clab;
mnt = pat.mnt;
Ax_all = pat.Ax_all;

params.clab = clab;
params.mnt = mnt;
n_channels = length(clab);
n_sources = params.n_components + params.n_cortical_noise_sources;

n_methods = length(method_info);


% objective function values for all methods
corr_z_vs_phi_est = zeros(n_methods, params.n_repetitions);
corr_phi_vs_phi_est = zeros(n_methods, params.n_repetitions);
emd = zeros(n_methods, params.n_repetitions);
pattern_gt = zeros(n_channels, params.n_repetitions);
rho_empirical_tr = zeros(1, params.n_repetitions);
rho_empirical_te = zeros(1, params.n_repetitions);

method_names = cell(1,length(method_info));
for k=1:length(method_info)
    method_names{k} = method_info{k}{1};
end


%% start repetitions loop
params_outter  = params;
for n=1:params.n_repetitions
    set_localpaths();
    params = params_outter;
    
    fprintf('\niteration: %03d / %03d\n', n, params.n_repetitions);

%% create patterns
    Ax = Ax_all(:,randperm(size(Ax_all,2), n_sources));
   
%% create data
    fprintf('creating data ...')
    n_target_sources= params.n_components;
    n_noise_sources = params.n_cortical_noise_sources;
    n_epos = params.n_train_epos + params.n_test_epos;    
    
    % For each repetition, the frequency of interest is randomly chosen
    % The bandwidth is always 2 Hz
    fc = 5 + (30-5).*rand(1);
    
    params = setfield(params,'frequency_band',fc+[-1 1]);
    
    [X, z, S_x] = create_freq_spoc_data(...
        n_target_sources, n_noise_sources, ...
        params.frequency_band, params.fs, n_epos, params.epoch_length, ...
        params.amplitude_modulation_cutoff, params.amplitude_minimum, ...
        Ax, params.SNR, params.ratio_sn_to_cn, ...
        params.rho_th);
    
    tr_idx = 1:round(params.epoch_length*params.n_train_epos*params.fs/1000); 
    te_idx = (tr_idx(end)+1):size(X,2);
    
    z_tr = z(1,tr_idx);
    z_te = z(1,te_idx);
    
    X_tr = X(:,tr_idx);
    X_te = X(:,te_idx);
    
    sx_tr = S_x(1,tr_idx);
    sx_te = S_x(1,te_idx);
    
    
    pattern_gt(:,n) = Ax(:,1);
    
    
    Te = params.fs*params.epoch_length/1000;
    X_tr_epo = permute(reshape(X_tr', [Te, params.n_train_epos, size(X,1)]), [1,3,2]);
    z_tr = mean(reshape(z_tr, [Te, params.n_train_epos]));
    sx_tr_epo = reshape(sx_tr, [Te, params.n_train_epos]);
    phi_tr = var(sx_tr_epo);
    
    X_te_epo = permute(reshape(X_te', [Te, params.n_test_epos, size(X,1)]), [1,3,2]);
    z_te = mean(reshape(z_te, [Te, params.n_test_epos]));
    sx_te_epo = reshape(sx_te, [Te, params.n_test_epos]);
    phi_te = var(sx_te_epo);
    
    rho_empirical_tr(n) = corr(phi_tr', z_tr');
    rho_empirical_te(n) = corr(phi_tr', z_tr');
    
    fprintf(' done\n');
    
    %% compare algorithms 
    for k=1:n_methods
        fprintf('starting %s\n', method_info{k}{1})
        % train
        train_func = method_info{k}{2}; % get the current method's function handle
        apply_func = method_info{k}{3}; 
        method_params = method_info{k}{4};        
        getpatt_func = method_info{k}{5};
        
        method_params = setfield(method_params,'fband',params.frequency_band);
        
        method_params = merge_structs(method_params, params);
        
        % train
        [w, h] = train_func(X_tr_epo, z_tr, method_params); % call the current method
        
        % test
        phi_est = apply_func(w, h, X_te_epo, method_params);
        
        % comparison metrics
        corr_z_vs_phi_est(k,n) = corr(z_te', phi_est');
        corr_phi_vs_phi_est(k,n) = corr(phi_te', phi_est');
        
        if ~isempty(getpatt_func)
            pattern_est = getpatt_func(w,h,X_te_epo,method_params);
        end
        
        % earth movers distance
        emd(k,n) = custom_EMD(pattern_gt(:,n),pattern_est,clab);
      
        fprintf('   z vs phi_est = %1.4f\n',corr_z_vs_phi_est(k,n));
        fprintf('   phi vs phi_est = %1.4f\n',corr_phi_vs_phi_est(k,n));
        fprintf('   emd = %1.4f\n',emd(k,n));
        fprintf('\n')
    end
end

params_outter.method_names = method_names;

%% save results

results.corr_z_vs_phi_est = corr_z_vs_phi_est;
results.corr_phi_vs_phi_est = corr_phi_vs_phi_est;
results.emd = emd;

if not(isempty(params_outter.result_path))
    save(file_path, 'params_outter', 'results');
end

%% plot
if params.plot
    legend_string = method_names;
    
    tmp_result = {
        {corr_phi_vs_phi_est', 'xval source p vs est source p',[-0.2,1]}
        {corr_z_vs_phi_est', 'xval z and est source p',[-0.2,1]}
        {emd', 'emd',[]}
        };
    figure
    K = length(tmp_result);
    for k=1:K
        
        dat = tmp_result{k}{1};
        
        subplot(1,K,k)
        plot(dat);
        title(tmp_result{k}{2})
        legend(legend_string)
        if not(isempty(tmp_result{k}{3}))
            ylim(tmp_result{k}{3})
        end
    end
end   



