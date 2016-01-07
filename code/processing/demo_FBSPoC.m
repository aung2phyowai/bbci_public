% Demo script for the Filter-Bank SPoC algorithm
%
% jscastanoc@gmail.com
% 1st sep 2015

close all; clear; clc
set_localpaths;

%% Simulate data set
SNRse = 5; % SNR on the sensor level (dB)
SNRso = -0.5; % SNR on the source level
Nc = 10; % Number of sensors
Nd = 20; % Number of sources
A = randn(Nc,Nd); % Pattern/mixing matrix
Ne = 1000; % Number of epochs in the dataset
fs = 200; % Sample frequency
Te = 200; % Samples per trial

tband = [8 10];
data = struct;
data.fs = fs;
[data.x, data.z] = custom_simSources(SNRse, SNRso, A, Ne, fs, Te,...
    'target_band', tband, 'noise_narrow', [11 13], ...
    'narrow_scale', 1);
[Nt, Nc, Ne] = size(data.x);

%% Set frequency bands for the filters
N_filt = 20;

% Generate (almost) logarithmic freq bands
fc = 2.^(1:.25:6);
fc = fc-min(fc) + 1;
bw = diff(fc);
fc = fc(2:end);

fbands = [];
figure('units','pixels','position',[200 200 600 200])
for idx_fband = 1:length(fc)
    fbands(idx_fband,:) = [fc(idx_fband)-bw(idx_fband), fc(idx_fband)+bw(idx_fband)];
    plot(fbands(idx_fband,:), [idx_fband, idx_fband]); hold on;
    plot([fbands(idx_fband,1), fbands(idx_fband,1)],[0 idx_fband]);
    plot([fbands(idx_fband,2), fbands(idx_fband,2)],[0 idx_fband]);
end
xlabel('frequency (Hz)')
title('freq. bands')


%% Train spatio-temporal SPoC filters
[w_spatial, h_temporal,extras] = train_FBSPoC(data.x,data.z,'fbands',fbands,'fs',data.fs);
z_est = apply_FBSPoC(w_spatial,h_temporal,data.x);
xval_final = corr(data.z(:),z_est(:));

%% (Overfitted) correlation for each of the frequency bands
figure('units','pixels','position',[200 200 500 200])
for idx_fband = 1:length(fc)
    xval = extras.xval_fwise(idx_fband);
    fbands(idx_fband,:) = [fc(idx_fband)-bw(idx_fband), fc(idx_fband)+bw(idx_fband)];
    plot(fbands(idx_fband,:), [xval, xval]); hold on;
    plot([fbands(idx_fband,1), fbands(idx_fband,1)],[0 xval]);
    plot([fbands(idx_fband,2), fbands(idx_fband,2)],[0 xval]);
end
xlabel('frequency (Hz)')
ylabel('correlation')
title(['correlation using all bands:' num2str(xval_final)])