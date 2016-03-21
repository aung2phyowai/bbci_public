function [X, z, S] = create_freq_spoc_data(...
    n_target_sources, n_noise_sources, ...
    frequency_band, sampling_rate, n_epos, epoch_length,  ...
    amplitude_modulation_cutoff, amplitude_minimum, ...
    Ax, SNR, ratio_sn_to_cn, rho_th)

T = n_epos * epoch_length/1000;

%% generate time course(s) of the target source(s)
    
[S_ts, Env_ts] = create_freq_spoc_source_signals(...
    n_target_sources, frequency_band, T, ...
    sampling_rate, amplitude_modulation_cutoff, ...
    sqrt(amplitude_minimum), [], []);

%% set correlation between envelope of target sources and z  

% (code from David Ramirez)
dummy = roots([4*rho_th^2 2*pi*rho_th^2 ((16 - pi^2)*rho_th^2 - pi^2/4) 2*pi*(rho_th^2 - 1) 4*(rho_th^2 - 1)]);
dummy(abs(imag(dummy))>0) = [];
dummy = dummy(dummy>=0);
sigma_amp = dummy(1);

env_noise = zeros(size(Env_ts));
N = length(env_noise);
for k=1:n_target_sources
    env_noise(k,:) = randn(1,N);
    [b,a] = butter(3,frequency_band(1,:)/sampling_rate*2);
    env_noise(k,:) = filtfilt(b,a,env_noise(k,:).').';
    env_noise(k,:) = env_noise(k,:)/sqrt(sum(env_noise(k,:).^2)/N);
    env_noise(k,:) = diag(sigma_amp)*abs(hilbert(env_noise(k,:).').');
end
    
env_x = Env_ts;
z = env_x + env_noise; % Adding noise to the amplitude to get the desired correlation coefficient
z = diag(1./sqrt(1 + sigma_amp.^2 + pi*sigma_amp/2))*z;  % Normalize to maintain the power
        


%% generate time course(s) of the background source(s)

n_pn_sources = ceil(n_noise_sources/3);
n_tb_sources = ceil(n_noise_sources/3);
n_nb_sources = n_noise_sources - n_pn_sources - n_tb_sources;


% background sources with 1/f spectrum -> pink noise
S_bs = mkpinknoise(size(S_ts,2), n_noise_sources)';

noise_bands = zeros(n_tb_sources+n_nb_sources, 2);
for k=1:size(noise_bands,1)
    if k <= n_tb_sources
        noise_bands(k,:) = frequency_band;
    else
        fc_ival = [3,45];
        fc = fc_ival(1) + rand * diff(fc_ival);
        tmp_band = 2.^[log2(fc)-0.25, log2(fc)+0.25];
        noise_bands(k,:) = tmp_band;
    end
end
    
for k=1:size(noise_bands,1)
    filter_order = 3;
    [b,a] = butter(filter_order, noise_bands(k,:)/sampling_rate*2);
    S_bs(n_pn_sources+k,:) = filtfilt(b,a,S_bs(n_pn_sources+k,:)')';
end
    

% %% sanity check: spectra of sources
% [~,freqs] = pwelch(S_bs(1,:),2*sampling_rate,[],[],sampling_rate,'onesided');
% P = zeros(n_noise_sources, length(freqs));
% for k=1:n_noise_sources
%     P(k,:) = pwelch(S_bs(k,:),2*sampling_rate,[],[],sampling_rate,'onesided');
% end
% figure, 
% imagesc(log(P))

%% project data to sensor level

% project target sources and background sources to sensor level
X_source = Ax(:,1:n_target_sources) * S_ts; % source activity
X_bg = Ax(:,(n_target_sources+1):end) * S_bs; % cortical background sources
X_sn = randn(size(X_bg)); % additional noise

% compute normalization constants
c_s = norm(X_source, 'fro');
c_sn = norm(X_sn, 'fro');
[b,a] = butter(filter_order, frequency_band/sampling_rate*2);
X_bg_bp = filtfilt(b,a,X_bg')';
c_bg = norm(X_bg_bp, 'fro');
 

% normalize and add data
X_source = X_source ./ c_s;
X_bg = X_bg ./ c_bg;
X_sn = X_sn ./ c_sn;

X_n = X_bg + ratio_sn_to_cn*X_sn;
% X_n = X_n ./ norm(X_n, 'fro');

X = SNR*X_source + X_n;

%% collect results

S = [S_ts; S_bs];

% %% sanity check: -> spectra of signal and noise data in sensor space
% cnt_tmp = [];
% cnt_tmp.fs = sampling_rate;
% 
% cnt_tmp.x = X_source';
% spec_xs = proc_spectrum(cnt_tmp,[1,50], 'db_scaled', 0);
% 
% cnt_tmp.x = X_n';
% spec_xn = proc_spectrum(cnt_tmp,[1,50], 'db_scaled', 0);
% 
% cnt_tmp.x = X';
% spec_x = proc_spectrum(cnt_tmp,[1,50], 'db_scaled', 0);
% 
% figure, 
% rows = 2;
% cols = 1;
% 
% subplot(rows,cols,1)
% plot(spec_xs.t, [mean(spec_xs.x,2), mean(spec_xn.x,2), mean(spec_x.x,2)])
% title('power spectra, averaged over channels')
% xlabel('frequency [Hz]')
% ylabel('power')
% 
% subplot(rows,cols,2)
% plot(log(spec_xs.t), log([mean(spec_xs.x,2), mean(spec_xn.x,2), mean(spec_x.x,2)]))
% title('power spectra, averaged over channels (log-log)')
% xlabel('log frequency')
% ylabel('log power')
