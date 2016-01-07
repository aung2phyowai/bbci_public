function fv = get_var_features(W, Cxxe)
Ne = size(Cxxe,3);
fv = zeros(size(W,2),Ne);
for e=1:Ne
    fv(:,e) = diag(W'*Cxxe(:,:,e)*W);
end