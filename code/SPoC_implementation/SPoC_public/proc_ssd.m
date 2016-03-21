function [cnt_ssd, W, A, score, C_s]= proc_ssd(cnt, varargin)
%PROC_SSD - Spatio-Spectral Decomposition
%
%Description:
% Calculates spatial filters using SSD,
% based on the paper "A novel method for reliable and fast extraction of
% neuronal EEG/MEG oscillations on the basis of spatio-spectral
% decomposion" by V. Nikulin, G. Nolte, and G. Curio (NeuroImage 2011)
%
%Synopsis:
% [DAT, SSD_W, SSD_A, SSD_EIG]= proc_ssd(CNT, <OPT>);
%
%Arguments:
% provide either dat_flt_s and dat_flt_n or cnt and band!
% DAT    - data structure of continous data (can be epoched if already
%           bandpass filtered
%
% OPT - struct or property/value list of optional properties:
%  'band' - frequency band of interest, e.g. [8, 13]
%  'delta_f' - width of side bands (usually 1-2 Hz)
%  'filter_order' - order of bandpass filter (butterworth)
%     If bandpassed data is available, it can given as
%  'dat_flt_s' - data filtered in the frequency band of interest (e.g.
%                   alpha)
%  'dat_flt_n' - data filtered for the noise bands
%  'stopBandMargin' - specifies the freq. range around the signal
%
%
%Returns:
% CNT     - data projected onto SSD components
% SSD_W  - SSD projection matrix (filters, in the columns)
% SSD_A  - estimated mixing matrix (activation patterns, in the columns)
% SSD_EIG- eigenvalue score of SSD projections
%
%
% Author(s): Franziska Horn, Sven Daehne
 
def_deltaF = 2;
def_flankingBand = [];
def_band = [8 13];
def_datFltS = [];
def_datFltN = [];
def_filterOrder = 4;
def_stopBandMargin = [-1, 1];

p = inputParser;

addParameter(p,'delta_f',def_deltaF);
addParameter(p,'flanking_band',def_flankingBand);
addParameter(p,'band',def_band);
addParameter(p,'dat_flt_s',def_datFltS);
addParameter(p,'dat_flt_n',def_datFltN);
addParameter(p,'filter_order',def_filterOrder);
addParameter(p,'stopBandMargin',def_stopBandMargin);

parse(p,varargin{:})
opt = p.Results;

% opt= set_defaults(propertylist2struct(varargin{:}), ...
%                   'delta_f', 2, ...
%                   'flanking_band', [], ...
%                   'band', [8 13], ...
%                   'dat_flt_s', [], ...
%                   'dat_flt_n', [], ...
%                   'filter_order', 4, ...
%                   'stopBandMargin',  [-1, 1]);

%% filter the data
opt.filter_order = 4;
% determinating the signal around the freq. band of interest
if isempty(opt.dat_flt_s)
    if sum(opt.band) == 0
        display('either dat_flt_s or band has to be given')
        return
    end
    [b,a] = butter(opt.filter_order, opt.band/cnt.fs*2); %lowpass filter 
    dat_flt_s = proc_filtfilt(cnt, b, a); % "signal"
else
    dat_flt_s = opt.dat_flt_s;
end

% determinating the noise 
if isempty(opt.dat_flt_n)
    if sum(opt.band) == 0
        display('either dat_flt_n or band has to be given')
        return
    end
    if isempty(opt.flanking_band)
        band_flanking = opt.band + [-1, 1]*opt.delta_f; % delta_f should be >= 2 Hz
    else
        band_flanking = opt.flanking_band;
    end
    [b,a] = butter(opt.filter_order, band_flanking/cnt.fs*2); %first step: band pass in the range [f-delta_f,f+delta_f]
    dat_flt_n = proc_filtfilt(cnt, b, a);
    band_stop = opt.band + opt.stopBandMargin;
    [b,a] = butter(opt.filter_order, band_stop/cnt.fs*2,'stop'); %second step: band-stop filtering around f
    dat_flt_n = proc_filtfilt(dat_flt_n, b, a); % "noise"
else
    dat_flt_n = opt.dat_flt_n;
end

%% compute covariance matrix of signal and noise

if ndims(dat_flt_s.x)==3 %for epoched data structure
    [T,N,E] = size(dat_flt_s.x);
    X_s = reshape(permute(dat_flt_s.x, [1,3,2]), [T*E, N]);
else
    X_s = dat_flt_s.x;
%     X_s = X_s-repmat(mean(X_s),size(X_s,1),1); %remove the mean
end
C_s = cov(X_s); %time-averaged covariance of the signal, cov() removes the mean

if ndims(dat_flt_n.x)==3
    [T,N,E] = size(dat_flt_n.x);
    X_n = reshape(permute(dat_flt_n.x, [1,3,2]), [T*E, N]);
else
    X_n = dat_flt_n.x;
%     X_n = X_n-repmat(mean(X_n),size(X_n,1),1); %remove the mean
end
C_n = cov(X_n); %time-averaged covariance of the noise

%% do actual SSD calculation as generalized eigenvalues
[W,D]= eig(C_s,C_n); %compute filter W for SSD decomposition
% [W,D]= eig(pinv(C_n)*C_s,'qz'); 
% [W,D]= eig(pinv(C_n)*C_s); 
% [U,S,V] = svd(inv(C_n)*C_s);
% W = U;
% D = S;
score= diag(D);
W = W(:, size(W,2):-1:1); % flipping the order of the columns => why?
score = score(size(W,2):-1:1); % flipping the order of the corresponding eigenvalues as well

%% normalize filters
for k=1:size(W,2)
    W(:,k) = W(:,k)/sqrt(W(:,k)'*C_s*W(:,k)); % why normalizing again?
end
   
%% apply SSD filters to time series
if not(isempty(cnt))
    cnt_ssd = proc_linearDerivation(cnt, W, 'prependix','ssd'); %now the channels are "SSD-subspaces" resulting from the different eigenvalues
else
    cnt_ssd = [];
end


%% compute patterns
A = inv(W)';