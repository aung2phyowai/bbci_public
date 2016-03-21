function [s , env] = create_random_narrowband_signal_using_FFT(n_sources, band, T, fs)

if length(band) == 1
    band = [band, band];
end

N = T*fs;

f_ny = floor(fs/2);
df = 1/T;
freqs = 0:df:f_ny;
n_freqs = length(freqs);
band_idx = band(1) <= freqs  & freqs <= band(2); 

% create the fourier spectrum, i.e. amplitudes and phases
Amps = zeros(n_freqs, n_sources);
Amps(band_idx, :) = 1;
bins_left = T*fs - n_freqs;
Amps = [Amps; zeros(bins_left ,n_sources)];
rand_phases = rand(size(Amps))*2*pi - pi;
% put amps and phases together for complex Fourier spectrum
S = Amps .* exp(1i*rand_phases);
% project the complex spectrum back to the time domain
s = real(ifft(S, 'symmetric'))';

% create the hilbert transform to get the envelope of the time series
h = zeros(size(S));
h(1,:) = 1;
h(2:n_freqs, :) = 2;
Sh = S .* h;
sh = ifft(Sh);
env = abs(sh)';

