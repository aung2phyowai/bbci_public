function [w_spatial, h_temporal] = train_PCA(X, z, varargin)
% [w_spatial, h_temporal] = train_PCA(X, z, options)
% Extract principal component to predict target variable (naive
% approach/worst case after random filtering)
%
% Arguments:
%   X:      ARRAY NcxNtxNe. Array containing the epoched EEG data (Number
%   of channels x Number of samples per epoch x Number of epochs
%   z:      VECTOR  Ne. Vector with the target variables for each of the
%   epochs
%
% Output:
%   w_spatial:  VECTOR Nc. Spatial filter.
%   h_temporal: VECTOR N_filt. FIR filter.
%
% sebastian.castano@blbt.uni-freiburg.de
% May 2015
%

options = propertylist2struct(varargin{:});
options = set_defaults(options,...
    'N_filt', 40,... % Filter order
    'fband', [8 10],...% Frequency where the source of interest is
    'fs', 200);  % Sample frequency

Nc = size(X,2);
Te = size(X,1);
Ne = size(X,3);

% design filter in the predefined band
Hbandp = designfilt('bandpassfir','DesignMethod','Window', ...
        'FilterOrder',options.N_filt,...
        'CutoffFrequency1', options.fband(1),...
        'CutoffFrequency2', options.fband(2),...
        'SampleRate', options.fs);
if Ne > 1
    X_cnt = permute(X,[1,3,2]);
    X_cnt = reshape(X_cnt, [Te*Ne,Nc]);
else
    X_cnt = X;
end

% perform filtering on each channel
X_filt = zeros(size(X_cnt));
for n_channel = 1:Nc
    X_filt(:,n_channel) = filtfilt(Hbandp,X_cnt(:,n_channel));
end
clear X_cnt

% X_filt = permute(reshape(X_filt, [Te, Ne, Nc]), [1,3,2]);
Cxx = X_filt'*X_filt;

% [w_spatial] = spoc(X_filt, z);
[U,S,V] = svd(Cxx);

w_spatial = U(:,1);
h_temporal = Hbandp;


