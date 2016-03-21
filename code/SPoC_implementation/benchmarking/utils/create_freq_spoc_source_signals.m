function [S, S_env] = create_freq_spoc_source_signals(n_sources,...
    band, T, fs, env_mod_lp_cutoff_freq, offset, S, S_env)
% Creates n oscillatory signals with a given carrier frequency and slowly 
% varying amplitude.
%
% Params:
%   n_sources       - number of signals to generate
%   band            - frequency of the oscillation
%   T               - desired length of the signals, given in seconds
%   fs              - desired sampling rate
%   env_mod_lp_cutoff_freq  - the cutoff frequency for the low-pass
%                   filtered envelope
%   offset          - min(envelope) will be 0 + offset


f_env = env_mod_lp_cutoff_freq;
if not(isempty(f_env)) && not(length(f_env)==1) && not(length(f_env) == n_sources)
    error('f_env must have length 0, 1, or n_sources')
end

N = fs*T;
if not(exist('S', 'var')) || isempty(S)
    % create random source signals
    [S, env] = create_random_narrowband_signal_using_FFT(n_sources, band, T, fs);
end
% normalize all envelopes
% env = abs(hilbert(S'))'; % compute and store the envelopes
S = S./env; % normalize source signals to have unit envelope

if not(exist('S_env', 'var')) || isempty(S_env)
    if isempty(f_env)
        S_env = env;
    else
        % add some buffer at the beginning of the envelope, so that we dont
        % have boundary effects of the lowpass filter
        buffer_length = min(100*fs, N);
        S_env = randn(size(S,1), size(S,2)+buffer_length);
        tmp = S_env;
        % lowpass filter the envelopes
        if length(f_env)==1
            [b,a] = butter(3,f_env/fs*2);
            tmp_flt = filter(b, a, tmp')';
            S_env = tmp_flt(:,buffer_length+1:end);
        else
            for k=1:n_sources
                [b,a] = butter(3,f_env(k)/fs*2);
                tmp_flt = filter(b, a, tmp(k,:));
                % store the filtered envelope without buffer part
                S_env(k,:) = tmp_flt(buffer_length+1:end);
            end
        end
    end
end

n_samples = size(S_env,2);
% make sure the filtered envelope is non-negative (can happen after
% filtering...)
S_env = S_env - repmat(min(S_env,[],2), [1,n_samples]);
% normalize to unit variance
S_env = S_env ./ repmat(std(S_env,[],2), [1,n_samples]);
% add an offset
S_env = S_env + offset;
% apply the envelope modulation to the source signal
S = S .* S_env;
% normalize the time courses
for k=1:size(S,1)
    sigma = std(S(k,:));
    S(k,:) = S(k,:) ./ sigma;
    S_env(k,:) = S_env(k,:) ./ sigma;
end
    
