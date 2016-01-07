function [X_epo, z_epo] = custom_simSources(SNRse, SNRso, A, Ne, fs, Te, varargin)
% Input
%       SNRse. scalar. SNR at sensor level in decibels
%       SNRso. scalar. SNR at source level (between 0 and 1) in terms of 
%                       variance explained by the target source
%       A. Matrix [N-channels x N-sources]. Mixing matrix forward operator
%       Ne. scalar. Number of trials
%       fs. scalar. Sample frequency
%       Te. scalar. Number of time samples per trial
%       
%       For optional input arguments (key-value) see below
%  
% Sebastian Castano-Candamil
% Based on the following function found in the repository by Sven Daehne
% https://github.com/svendaehne/matlab_SPoC/blob/master/SPoC/spoc_example.m
% sebastian.castano@blbt.uni-freiburg.de
% 4th March 2015

% Optional input arguments and the corresponding default values
def_target_band = [8 10]; % Frequency band co-modulating with the target variable
def_noise_narrow = []; % Background sources with narrow-band activity [ 2 x number of sources with narrow band activity
def_narrow_scale = 1; % Scale of the narrow band background sources (length of the vector)
p = inputParser;

addParameter(p,'target_band',def_target_band);
addParameter(p,'noise_narrow',def_noise_narrow);
addParameter(p,'narrow_scale',def_narrow_scale);

parse(p,varargin{:})
options = p.Results;


% SNR = 0.2; % signal-to-noise ratio (between 0 and 1) in terms of variance explained by the target source
Ns = size(A,2); % number of sources, the first one is the 'target source'
Nx = size(A,1); % number of simulated EEG sensors, 
% Ne_tr = 50; % number of training epochs/trials
% Ne_te = 50; % number of test epochs/trials
% Ne = Ne_tr + Ne_te;
% Te = 200; % number of samples per epoch

% samples_per_second = 100;

% tr_idx = 1:Ne_tr;
% te_idx = (1:Ne_te) + Ne_tr;

% make sure the SNR is between 0 and 1
% SNRso = max(0,SNRso);
% SNRso = min(1,SNRso);


%% data in source space

S = mkpinknoise(Te*Ne, Ns);
% S(:,1) = randn(Te*Ne, 1);
[b,a] = butter(5, options.target_band/fs*2);
S_narrow= filtfilt(b, a, S);

if ~isempty(options.noise_narrow)
    idx_narrow_noise = randi(Ns-1,size(options.noise_narrow,1));
    idx_band = 1;
    for idx_source = idx_narrow_noise
        band_2 = randn(Te*Ne, 1);
        [b,a] = butter(5, options.noise_narrow/fs*2);
        band_2 = filtfilt(b, a, band_2);
        idx_band = idx_band +1;
        S(:,idx_source) = options.narrow_scale*band_2/norm(band_2,'fro');
    end
end

S(:,1) = S_narrow(:,1);

S_env = abs(hilbert(S));
DS = S ./ S_env;

[b,a] = butter(5, 0.25/fs*2);
S_env_slow= filtfilt(b, a, S_env);

S = DS .* S_env_slow;

z = S_env_slow(:,1).^2;  % Target function for SPoC analysis: the actual 
                    % squared envelope (i.e. power time course) of one of
                    % the sources. The task is to recover exactly that
                    % source.

% plot source signals
% figure
% plot_time_courses(zscore(S), 1,'s', 1);
% title({'data in source space', 's_1 is the target source'})
% xlabel('time')
% set(gca, 'xtickLabel',[])
% ylabel('sources')

Nx= size(A,1);
%% mix the sources

% project sources to sensors (i.e. mix the sources)
X_s = S(:,1) * A(:,1)';
X_bg = S(:,2:end) * A(:,2:end)';

X_s = X_s ./ norm(S_narrow(:,1),'fro');
X_bg = X_bg ./ norm(S_narrow(:,2:end),'fro');
X = X_s + (1-SNRso)*X_bg;

% add some small sensor noise
X_noise = randn(size(X));
allchanstd=(std(X'));
meanrmssignal=mean(allchanstd);
noise_scale = meanrmssignal/10^(SNRse/20);

X = X + noise_scale*X_noise;

%% reshape sensor signals into epochs

X_epo = permute(reshape(X, [Te, Ne, Nx]), [1,3,2]);
z_epo = mean(reshape(z, [Te, Ne]));

% split training and test data
% X_tr = X_epo(:,:,tr_idx);
% z_tr = z_epo(tr_idx);

% X_te = X_epo(:,:,te_idx);
% z_te = z_epo(te_idx);
