function [w_spatial, h_temporal, extras] = train_FBSPoC(X, z, varargin)
% [w_spatial, h_temporal] = trainFBSPoC(X, z, options)
% Train temporal and spatial filters for X to estimate z 
% The parameters of each of the filters is hard coded (see below)
%
% Arguments:
%   X:      ARRAY NcxNtxNe. Array containing the epoched EEG data (Number
%   of channels x Number of samples per epoch x Number of epochs
%   z:      VECTOR  Ne. Vector with the target variables for each of the
%   epochs
%
% Output:
%   w_spatial:  STRUCT. Contains the spatial filters computed for all freq. bands and the regressor to compute the final estimation.
%   h_temporal: CELL. Contains the filters for each of the frequency bands.
%
% sebastian.castano@blbt.uni-freiburg.de
% May 2015

[Te, Nc, Ne] = size(X);

options = propertylist2struct(varargin{:});
options = set_defaults(options,...
    'fbands', [],... % Freq-bands for the band-pass filters of the filter bank
    'fs', nan); % Sample frequency of X

if isempty(options.fbands)
    fc = 2.^(1:.25:6);
    fc = fc-min(fc) + 1;
    fc = fc(2:end);
    fbands = zeros(length(fc),2);
    for idx_band = 1:size(fbands,1);
        fbands(idx_band,:) = 2.^(log2(fc(idx_band))+[-.25, .25]);        
    end
else
    fbands = options.fbands;
end

% Build band-pass filters
for idx_band = 1:size(fbands,1);
    if fbands(idx_band,2)/(options.fs/2) <= 1
        d{idx_band} = fdesign.bandpass('N,Fp1,Fp2,Ast1,Ap,Ast2',...
            40,fbands(idx_band,1)/(options.fs/2),...
            fbands(idx_band,2)/(options.fs/2), 30, 1, 30);
        Hd{idx_band} = design(d{idx_band});
    else
        fbands(idx_band,:) = [NaN, NaN];
    end
end

% Compute spoc for each of the freq. bands
W = [];
A = [];
X_cnt = permute(X,[1,3,2]);
X_cnt = reshape(X_cnt, [Te*Ne,Nc]);

xval_fwise = nan(numel(Hd),1);
fprintf('Training FB-SPoC\n')
for idx_filt = 1:numel(Hd)    
    fprintf('Filtering data with filter %d\n',idx_filt)
    
    % Filter continous data and re-epoch
    X_filt = filter(Hd{idx_filt},X_cnt);
    X_filt = permute(reshape(X_filt, [Te, Ne, Nc]), [1,3,2]);
    
    [Wtmp, Atmp] = spoc(X_filt,z);
    if size(Wtmp,2) > 1
        Wtmp = Wtmp(:,1);
        Atmp = Atmp(:,1);
    end
    W = [W, Wtmp];
    A = [A, Atmp];
    
    for idx_trial = 1:Ne
        Xe = squeeze(X_filt(:,:,idx_trial));
        temp = Xe*Wtmp;
        z_est(idx_filt,idx_trial) = temp'*temp;
    end
    z_est(idx_filt,:) = zscore(z_est(idx_filt,:));
    xval_fwise(idx_filt) = corr(z_est(idx_filt,:)',z(:));
end
disp('...done!')

C = train_linReg(z_est,z,0);

% Pack filters and corresponding regression indices to latter merge the
% estimations of all the filters
Wpacked = struct('spatial_filt',W, 'reg_coef', C);
w_spatial = Wpacked;
h_temporal = Hd;

extras.xval_fwise = xval_fwise;


