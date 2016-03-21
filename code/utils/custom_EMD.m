function distance = custom_EMD(Sol1, Sol2, clab)
% distance = custom_EMD(Sol1, Sol2, clab)
% Computes the earth moving distance between two patterns
% Input:
%       Sol1 and Sol2 -> Ncx1. Patterns to compare
%       aff -> NdxNd. distance matrix between all the dipoles.
% Output:
%       distance -> Scalar. Earth mover's distance.
%
% sebastian.castano@blbt.uni-freiburg.de
% 14th April 2015
%
% Wrapper for: http://www.ariel.ac.il/sites/ofirpele/FASTEMD/code/
%

mfilepath=fileparts(which(mfilename));
addpath(fullfile(mfilepath,'/external'));
% addpath('external/');

mnt = mnt_setElectrodePositions(clab);
cpos = [mnt.x, mnt.y];
aff = squareform(pdist(cpos));

Sol1 = abs(Sol1).^2;
Sol2 = abs(Sol2).^2;

sig1 = Sol1 / norm(Sol1);
sig2 = Sol2 / norm(Sol2);



idx1 = find(sig1);
idx2 = find(sig2);

[distance,~]= emd_hat_gd_metric_mex(sig1(idx1),sig2(idx2),aff(idx1,idx2));
end
