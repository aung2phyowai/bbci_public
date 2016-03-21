function [fv, epo_spoc] = project_to_SPoC_var_features(W, epo, opt, Cxxe)
% function fv = project_to_SPoC_var_features(W, epo, opt, Cxxe)
% computes the variance of each epoch (which is the bandpower), if the filter W is applied on the
% epoch-wise covariance matrix Cxxe
% alternatively: apply filter W on the data X and compute the envelope
if exist('Cxxe', 'var')
    N_e = size(Cxxe,3);
    fv = zeros(size(W,2), N_e);
    for k=1:N_e
        fv(:,k) = diag(W'*Cxxe(:,:,k)*W);
    end
else
    % project data onto SPoC components
    epo_spoc = proc_linearDerivation(epo, W);
    % compute variance features
    epo_spoc_var = proc_variance(epo_spoc);
    fv = squeeze(epo_spoc_var.x);
end
if isfield(opt, 'use_log') && opt.use_log
    min_fv = min(fv(:));
    if min_fv <= 0
        fv = fv + 1.1*abs(min_fv);
    end
    fv = log(fv);
end
if size(W, 2) == 1
    fv = fv(:)';
end
