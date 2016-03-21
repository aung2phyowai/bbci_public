function C_n = proc_getCnoise(epo, varargin)
% proc_getCnoise() computes the noise covariance matrix contained at the 
% edges of a given frequency band. ( according to Eq. (10) in Nikulin et. 
% al 2011, NeuroImage)
%
%Synopsis:
% C_n = proc_getCnoise(epo)
%
%Arguments:
% epo - epoched data 
%
%Returns:
% C_n - noise matrix
%
% Author: Andreas Meinel (Dec. 2014)

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
    [b,a] = butter(opt.filter_order, band_flanking/epo.fs*2); %first step: band pass in the range [f-delta_f,f+delta_f]
    dat_flt_n = proc_filtfilt(epo, b, a);
    band_stop = opt.band + opt.stopBandMargin;
    [b,a] = butter(opt.filter_order, band_stop/epo.fs*2,'stop'); %second step: band-stop filtering around f
    dat_flt_n = proc_filtfilt(dat_flt_n, b, a); % "noise"
else
    dat_flt_n = opt.dat_flt_n;
end


if ndims(dat_flt_n.x)==3
    [T,N,E] = size(dat_flt_n.x);
    X_n = reshape(permute(dat_flt_n.x, [1,3,2]), [T*E, N]);
else
    X_n = dat_flt_n.x;
end

C_n = cov(X_n); %time-averaged covariance of the noise

end