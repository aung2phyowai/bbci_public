function [ ga ] = custom_grandAverage( erps,varargin )
%% PROC_GRANDAVERAGE -  calculates the grand average ERPs from given set of subjects.
%
%
% Input:    A cell array of epos, where erps{i} is the epoched data of subject i.
%             
% Output:   The combined and (optionally) weighted data of all subjects
%           combined in a epo struct
% 
%% Options
def_MustBeEqual = {'fs','className'};
def_Average = 'arithmetic'; 
p = inputParser;

addParamValue(p,'MustBeEqual', def_MustBeEqual);
addParamValue(p,'Average', def_Average); %'Nweighted'

parse(p,varargin{:})
opts = p.Results;

%% Preprocessing and Tests
if(~iscell(erps))
    error('Expects a struct of multiple epos as input!');
end    

datadim = unique(cellfun(@util_getDataDimension,erps));
if(datadim ~= 1)
   error('Expects 3-dimensional size(x) = [nSamples nChannels nTrials]'); 
end    

clab= erps{1}.clab;
for vp= 2:length(erps),
  clab= intersect(clab, erps{vp}.clab,'legacy');
end

ci = util_chanind(erps{1}, clab);
C = length(ci);
K = length(erps);
T =size(erps{1}.x,1);

ga = erps{1};

for vp = 1:K
    for jj= 1:length(opts.MustBeEqual),
        fld= opts.MustBeEqual{jj};
        if ~isequal(getfield(ga,fld), getfield(erps{vp},fld)),
            error('inconsistency in field %s.', fld);
        end
    end
end

nTrials = [];
for vp = 1:K
 n = size(erps{vp}.x,3);   
 nTrials = [nTrials n];
end 

N = sum(nTrials);    
X = zeros(T, C,N);

nClasses = size(erps{1}.y,1);
Y =zeros(nClasses,N);

%%populating the ga

for vp = 1:K
    ci= util_chanind(erps{vp}, clab);
    lowerbound = sum(nTrials(1:vp-1))+1;
    upperbound = sum(nTrials(1:vp));
    
    X(:,:,lowerbound:upperbound) = erps{vp}.x(:,ci,:);
    Y(:,lowerbound:upperbound) = erps{vp}.y;
end    

%% Prepare averaging
sW = 0;
for vp = 1:K
    switch opts.Average
        case 'Nweighted'
            W = nTrials(vp);
        otherwise
            W = 1;%case 'arithmetic'
    end
    sW = sW + W;
    lb = sum(nTrials(1:vp-1))+1;
    ub = sum(nTrials(1:vp));
    X(:,:,lb:ub) = W.*X(:,:,lb:ub);
end
X(:,:,:) = X(:,:,:)./sW;

ga.title = 'grand average';
ga.x = X;
ga.y = Y;
ga.clab = clab;
ga.prctile = erps{1}.prctile;
end

