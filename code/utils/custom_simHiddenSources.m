function [x, t, extras] = custom_simHiddenSources(Nc,fs,tl,t_var,fband,Nw,Nsin,snr, amp_ratio)
% function [x, t, extras] = custom_simHiddenSources(Nc,fs,tl,t_var,fband,Nw,Nsin,snr, amp_ratio)
% Generates pseudo EEG across Ntrials, with Ns modulated hidden sources
% Input:
%   Nc:     scalar. Number of pseudo-EEG channels
%   fs:     scalar. Sample frequency of the generated EEG
%   tl:     scalar. time length in seconds per epoch
%   t_var:  vector 1xNtrials. Target variable modulating the sources of
%   interest in each of the epochs/trials.
%   fband:  vector 1xNs. Vector with the frequency bands modulated by the
%   target variable t_var
%   Nw:     scalar. Number of noise sources modeled as real morlet wavelets
%   Nw:     scalar. Number of noise sources modeled as sine waves
%   snr:    scalar. Signal-noise ratio of the pseudo-EEG. Measurement (white) noise
%   is added to the pseudo-EEG to achieve this value
%   amp_ratio: scalar. Ratio between the amplitude of the sources of
%   interest and the noise sources.
% Output:
%   x:      array NtxNcxNtrials. Pseudo-EEG
%   t:      vector 1xNt. Contains the time vector for each of the epochs
%   extras: struct:
%           - empty
% 
% sebastian.castano@blbt.uni-freiburg.de
% 12. Jan. 2015

Ntrials = length(t_var);
t = 0:(1/fs):(tl);

%% Generate source of interest for each epoch and modulate it with the target variable

for i = 1:Ntrials
    for j = 1:length(fband)
        source(j,:,i) = t_var(i)*sin(2*pi*fband(j)*t);
    end
end


%% Spurious sources for each epoch

% Wavelets
NspuriousW = Nw;
freq_range = [1 fs/2];
for i = 1:Ntrials
    for j = 1:(NspuriousW)
        spurious(j,:,i) = gen_wavelet((freq_range(2)-freq_range(1))*rand(1),t,(t(end)-t(1))*rand(1));
        if j==NspuriousW
            spurious(j,:,i) =  (2*rand(1)+1)*gen_wavelet(14,t,0.5);
        end
    end
end

% Sine

% NspuriousW = Nsin;
freq_range = [1 fs/2];
for i = 1:Ntrials
    for j = NspuriousW+1:NspuriousW+Nsin
        spurious(j,:,i) = sin(2*pi*(freq_range(2)-freq_range(1))*rand(1)*t);
        if j==NspuriousW+Nsin
            spurious(j,:,i) = (2*rand(1)+1)*sin(2*pi*15*t);
        end
    end
end


%% Generate forward model, create pseudo-EEG and add gaussian noise for each epoc
A = randn(Nc,size(spurious,1)+size(source,1));
for i = 1:Ntrials
    s_tmp(:,:) = source(:,:,i);
    sp_tmp(:,:) = (1/amp_ratio)*spurious(:,:,i);
    tmp = A*[s_tmp;sp_tmp];
    x(:,:,i) =  add_noise(tmp,snr);
end

x = permute(x,[2 1 3]);
extras = struct;
end

function series = gen_wavelet(f0,t,time_shift)
% series = nip_gen_wavelet(f0,t,time_shift)
% Generate real morley wavelet along vector time t with central frequency f0 and
% phase shift phase_shit
% Normalization terms for the wavelet
%
% Input:
%       f0      -> scalar. central frequency of the wavelet
%       t       -> vector. time vector along which the wavelet is generated
%       time_shift -> scalar. time shift of the wavelet
%   
% Output:
%       series  -> vector. Wavelet generated
%
% Sebastian Castano 
% sebastian.castanoc@blbt.uni-freiburg.de
% 4th Dec. 2014
%

sigma_f = f0/7;
sigma_t = 1/(2*pi*sigma_f);

% "source" contains the time courses of active sources
series =  real(exp(2*1i*pi*f0*t).*...
    exp((-(t-time_shift).^2)/(2*sigma_t^2)));
end

function y = add_noise(x,snr)
% x = nip_addnoise(x,snr)
%   Input:
%       x -> NcxNt. Channel signals
%       snr -> scalar. Resulting SNR
%   Output:
%       y -> NcxNt. Signals with added white noise
% 
% Additional Comments:
% Based on a script written by Prof. Gareth Barnes
%
% Sebastian Castano
% 1st Feb 2013

allchanstd=(std(x'));
meanrmssignal=mean(allchanstd);
for i = 1:size(x,1)
    ch_noise = meanrmssignal.*randn(size(x(i,:)))/(10^(snr/20));
    allchannoise(i,:)=ch_noise;
    y(i,:) = x(i,:) + ch_noise;
end
end