function [distance, clab_new] = custom_getPatternDistance(A1, A2, clab1, clab2,...
    varargin)
% distance = custom_getPatternDistance(A1, A2, clab1, clab2)
% Computes the distance between two patterns by matching the channel labels
% 
% Input:
%       A1, A2 -> Ncx1. Patterns to compare (channel no. can be
%       different!)
%       clab1, clab2 -> channel labels of both patterns
% Output:
%       distance -> Scalar.
%       clab_new -> Matched channel labels
%
% andreas.meinel@blbt.uni-freiburg.de
% 1st September 2015
%

%% Set optional input values

def_method = 'euclidean';
p=inputParser;

addParameter(p,'method',def_method);

parse(p, varargin{:})
opts = p.Results;

%% Match the channel labels

clab_new = intersect(clab1,clab2);

idx_A1 = find(ismember(clab1,clab_new));
idx_A2 = find(ismember(clab2,clab_new));

A1_sel = A1(idx_A1);
A2_sel = A2(idx_A2);

%% Normalize and remove the sign of the patterns

A1 = A1_sel.^2;
A2 = A2_sel.^2;

A1 = A1/norm(A1);
A2 = A2/norm(A2);

%% Calculate distance

switch opts.method
    
    case 'euclidean'
        distance = sqrt(sum((A1-A2).^2));
        
    case 'angle'
        distance = acos((2*A1)/(norm(A1)*norm(A2)));
        
    case 'EMD'
        distance = custom_EMD(A1,A2,clab_new);

end

end
