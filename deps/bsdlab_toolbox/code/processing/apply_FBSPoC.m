function [z] = apply_FBSPoC(w_spatial, h_temporal, X, varargin)
% [z] = apply_FBSPoC(w_spatial, h_temporal, X, varargin)
% Apply spatial and temporal filters trained with train_FIRSPoC
%
% Arguments:
%   w_spatial:  STRUCT. Contains the spatial filters computed for all freq. bands and the regressor to compute the final estimation.
%   h_temporal: CELL. Contains the filters for each of the frequency bands.
%   X:      ARRAY NcxNtxNe. Array containing the epoched EEG data (Number
%   of channels x Number of samples per epoch x Number of epochs
%
% Output: 
%   z:  VECTOR Ne. Estimated target variable for each epoch
%
% sebastian.castano@blbt.uni-freiburg.de
% May 2015
%

[Te, Nc, Ne] = size(X);

X_cnt = permute(X,[1,3,2]);
X_cnt = reshape(X_cnt, [Te*Ne,Nc]);

fprintf('Applying FB-SPoC\n')
for idx_filt = 1:numel(h_temporal)    
    fprintf('Filtering data with filter %d\n',idx_filt)
    
    % Filter continuous data and then re-epoch
    X_filt = filter(h_temporal{idx_filt},X_cnt);
    X_filt = permute(reshape(X_filt, [Te, Ne, Nc]), [1,3,2]);
    
    for idx_trial = 1:Ne
        Xe = squeeze(X_filt(:,:,idx_trial));
        Wb = w_spatial.spatial_filt(:,idx_filt);
        temp = Xe*Wb;
        pseudo_z(idx_filt,idx_trial) = temp'*temp;
    end
    pseudo_z(idx_filt,:) = zscore(pseudo_z(idx_filt,:));
end

% Regress the different predictions using coefficients computed with
% training data (train_FBSPoC)
z = w_spatial.reg_coef.w'*pseudo_z;
z = zscore(z);