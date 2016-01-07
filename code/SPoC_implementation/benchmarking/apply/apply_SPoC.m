function [z] = apply_SPoC(w_spatial, h_temporal, X, varargin)
% [z] = apply_SPoC(w_spatial, h_temporal, X, varargin)
% Apply spatial and temporal filters trained with train_SPoC
%
% Arguments:
%   w_spatial:  VECTOR Nc. Spatial filter.
%   h_temporal: VECTOR N_filt. FIR filter.
%   X:      ARRAY NcxNtxNe. Array containing the epoched EEG data (Number
%   of channels x Number of samples per epoch x Number of epochs
%
% Output: 
%   z:  VECTOR Ne. Estimated target variable for each epoch
%
% sebastian.castano@blbt.uni-freiburg.de
% May 2015
%

% N_filt = length(h_temporal);
Ne = size(X,3);
Te = size(X,1);
Nc = size(X,2);
if Ne > 1
    X_cnt = permute(X,[1,3,2]);
    X_cnt = reshape(X_cnt, [Te*Ne,Nc]);
else
    X_cnt = X;
end

X_filt = zeros(size(X_cnt));
for n_channel = 1:Nc
    X_filt(:,n_channel) = filtfilt(h_temporal,X_cnt(:,n_channel));
end
clear X_cnt

X_filt = permute(reshape(X_filt, [Te, Ne, Nc]), [1,3,2]);

for idx_epoch = 1:Ne
    X_e = squeeze(X_filt(:,:,idx_epoch));
    
    % Apply spatial filter
    Qe = X_e*w_spatial;
    
    % Estimate target variable for the epoch
    z(idx_epoch) = Qe'*Qe;
end

z = zscore(z);