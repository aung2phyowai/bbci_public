% Regress spurious component using synthetic signals (demo of
% proc_regressOutComponent)
%
% Sebastian Castano
% 13th Nov. 2014
clear; close all; clc


fs = 120; % Sample frequency
t = (0:1/fs:1); % Time vector

%% Simulate spurious source
t_artifact = 0.8; % Time shift of the wavelet in seconds
n = length(t); 
lb = 40*(t(1)-t_artifact); % These two parameters modify the width of the wavelet
ub = 40*(t(end)-t_artifact);
[spurious_source, ~] = mexihat(lb,ub,n);

%% Simulate true activity
f_c = [10 15]; % Central frequency of the sine emulating true activity
y(1,:) = sin(2*pi*f_c(1)*t);
y(2,:) = sin(2*pi*f_c(2)*t);


Nc = 10; % Number of channels to simulate

c = randn(Nc,size(y,1)); % Coefficients for the linear combination of the two sources

x = c*y; % Final simulated activity

% Add artifact and gaussian noise
x_noisy = x + 10*repmat(spurious_source,size(x,1),1)+0*randn(size(x));

[x_clean, A, s_hat] = proc_regressOutComponent(x_noisy', spurious_source');

figure
subplot(3,1,1)
plot(t,x)
title('True')
subplot(3,1,2)
plot(t, x_noisy)
title('Contaminated')
subplot(3,1,3)
plot(t,x_clean);
title('Cleaned')