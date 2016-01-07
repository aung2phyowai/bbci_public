function Cxx = proc_getCxx(epo)
% proc_getCxx() computes the mean covariance matrix from epoched data over all
% epochs
%
%Description:
%
%Synopsis:
% Cxx = proc_getCxx(epo)
%
%Arguments:
% epo - epoched data 
%
%
%Returns:
% Cxx - ordinary covariance matrix, mean covariance matrix over all epochs e
%
% Author: Andreas Meinel (Dec. 2014)

N_e = size(epo.x,3); % total number of epochs
N_ch = size(epo.x,2);

Cxx = zeros(N_ch,N_ch);

for e=1:N_e
    X_e = squeeze(epo.x(:,:,e)); % take the matrix X_e for a fixed epoch e out of X
    % size of X_e=[n_samples_per_epoch, n_channels]
    Cxx = Cxx + cov(X_e);
end
Cxx = Cxx/N_e;

end