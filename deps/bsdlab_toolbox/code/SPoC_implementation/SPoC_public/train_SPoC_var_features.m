function [fv, W, r_values, out] = train_SPoC_var_features(epo, z, Cxxe, opt)

if not(isfield(opt, 'spoc_func'))
    opt.spoc_func = @spoc;
end

% train SPoC
opt.spoc_opt.Cxxe = Cxxe;
opt.spoc_opt.n_spoc_components = opt.spocNumOfComp;
[W, A, eig, ~, ~, ~, Cxxe] = opt.spoc_func(epo.x, z, opt.spoc_opt);

W = W(:,(1:opt.spoc_opt.n_spoc_components));
% get var features in SPoC space
fv = project_to_SPoC_var_features(W, epo, opt, Cxxe);

% sort components according to correlations on training set
R = corrcoef([z', fv']);
[r_values, sort_idx] = sort(abs(R(1,2:end)), 'descend');
fv = fv(sort_idx, :);
W = W(:,sort_idx);
out.sort_idx = sort_idx;
out.A = A(:, sort_idx);
out.eig = eig;
out.Cxxe = Cxxe;
% reporting the correlation values of each component since the lamdba-
% values are the covariance values!
out.r_values = r_values;

