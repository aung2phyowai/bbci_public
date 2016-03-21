function [X_new, A, s_hat] = proc_regressOutComponent(X, s)
% 
% [X_new, A, s_hat] = regress_out_component(X, s)
%
% Uses regression to remove the time course(s) contained in s from the data
% contained in X. s could be the eye movements measured with EOG channels
% and X could be the remaining EEG channels. In this case the EOG signal
% that is contained in X will be removed (as best as possible, assuming a
% stationary eye movement pattern).
% 
% For a detailed explaination of the approach see 
% Parra, L. C., Spence, C. D., Gerson, A. D., & Sajda, P. (2005), 
% "Recipes for the linear analysis of EEG. Neuroimage, 28(2), 326-341
%
% In:
%   X - data matrix of size(X) = [T, n_channels]
%   s - time course of components to be removed, size(s) = [T, n_components]
%       n_components can be more than one
%
% Out:
%   X_new - same as X with the contribution of s removed. size(X_new) =
%           size(X). Note that this method reduces the rank of X_new!
%   A   - pattern matrix of size(A) = [n_channels, n_components], which
%           shows how each of the components in s project to the channels
%           in X.
%   s_hat - the estimate of s, which is extracted from X

% 2014, sven.daehne@tu-berlin.de


T = size(X,1);
if not(size(s,1) == T)
    error('X and s must have the same number of samples! size(X,1) = %d, size(s,1) = %d', size(X,1),size(s,1));
end

% normalize component time course
s = s - repmat(mean(s),[T,1]);
s = s ./ repmat(std(s),[T,1]);

% regression filter and patterns for the components
Cx = X'*X;
Cs = s'*s;
W = Cx \ X' * s; % regression weights for s
A = Cx*W/Cs; % spatial patterns of s

% remove estimate of s from the data
s_hat = X * W;
X_new = X - s_hat*A';

