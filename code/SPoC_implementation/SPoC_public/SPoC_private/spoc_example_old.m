function spoc_example()
% A small example that illustrates how SPoC works and how it can be
% applied. In this example we assume that we have a certain number of
% channels (Nx), which are aranged in a square (so it's easy to plot spatial patterns). 
% The channels measure a mixture of source activity. The epoch-wise
% variance of one of the sources (target source) is the target variable z.
%
% Note that there is training and test data! 
%
% Run this script a few times to get a feeling for the influence of the
% paramters (SNR, Ns, Ne_tr, etc).


%% parameters

SNR = 0.3; % signal-to-noise ratio (between 0 and 1) in terms of variance explained by the target source
Ns = 5; % number of sources, the first one is the 'target source'
Nx = 5; % number of simulated EEG sensors, must be quadratic for the plotting to work
Ne_tr = 20; % number of training epochs/trials
Ne_te = 50; % number of test epochs/trials
Ne = Ne_tr + Ne_te;
Te = 200; % number of samples per epoch

tr_idx = 1:Ne_tr;
te_idx = (1:Ne_te) + Ne_tr;

% make sure the SNR is between 0 and 1
SNR = max(0,SNR);
SNR = min(1,SNR);
% SNR

%%
S = randn(Te*Ne, Ns);
[b,a] = butter(5, [2,3]/Te*2);
S = filtfilt(b, a, S);

%% data in source space

S = randn(Te, Ns, Ne);

% "measure" the power of the target source and store the result in z
z = var(squeeze(S(:,1,:)));

%% mix the sources

% create some random smooth source patterns
A = randn(Nx,Ns);
A = reshape(A, [sqrt(Nx),sqrt(Nx),Ns]);
for k=1:Ns
    pattern = A(:,:,k);
    pattern = conv2(pattern, ones(3,3), 'same');
    A(:,:,k) = pattern;
end
A = reshape(A, [Nx, Ns]);

% create the time-courses
X_s = zeros(Te, Nx, Ne); 
X_bg = zeros(Te, Nx, Ne);
for k=1:Ne
    X_s(:,:,k) = S(:,1,k) * A(:,1)';
    X_bg(:,:,k) = S(:,2:end,k) * A(:,2:end)';    
end
X_s = X_s ./ norm(X_s(:),'fro');
X_bg = X_bg ./ norm(X_bg(:),'fro');
X = SNR*X_s + (1-SNR)*X_bg;

% add some small sensor noise
X_noise = randn(size(X));
X_noise = X_noise/norm(X_noise(:),'fro');
X = X + 0.05*X_noise;


% split training and test data
X_tr = X(:,:,tr_idx);
z_tr = z(tr_idx);

X_te = X(:,:,te_idx);
z_te = z(te_idx);

%% unmix with SPoC, only using training data

[W,A_est,lambda] = spoc(X_tr,z_tr);


%% project data to first SPoC component

s_est = zeros(Te, Ne);
for k=1:Ne
    s_est(:,k) = squeeze(X(:,:,k)) * W(:,1);
end

p_est = var(s_est);


%% compare correlations obtained using channelwise power versus using SPoC component power

P = squeeze(var(X_te)); % channel-wise power (variance)
r = corr([z_te',P']);
r = r(1,2:end);

r_spoc_tr = corr(z_tr',p_est(tr_idx)');
r_spoc_te = corr(z_te',p_est(te_idx)');

%% plot stuff
rows = 3;
cols = 4;
figure


% source power time-courses
subplot(rows,cols,1:2)
imagesc(squeeze(var(S)))
title('epoch-wise power in source space')
xlabel('epochs')
ylabel('sources')

% channelwise power time-courses
subplot(rows,cols,3:4)
imagesc(squeeze(var(X)))
title('epoch-wise power in sensor space')
xlabel('epochs')
ylabel('sensors')


% visualize lambdas
subplot(rows,cols,5)
bar(lambda)
title('SPoC lambda values')
xlabel('SPoC components')
xlim([0 length(lambda)+1])

% scatter true and estimated power
subplot(rows,cols,6)
scatter(zscore(z_te), zscore(p_est(te_idx)))
xlim([-3,3])
ylim([-3,3])
box on
title({'scatter between true source power', 'and estimated source power (on test data)'})
axis square


% correlations
subplot(rows,cols,7:8)
hold on
box on
plot(r, 'k')
plot(ones(size(r))*r_spoc_tr,'--r')
plot(ones(size(r))*r_spoc_te,'r')
title({'correlation of power with target function'})
xlim([0,Nx+1])
ylim([-0.2,1.3])
set(gca, 'ytick', -1:0.2:1)
xlabel('channel index')
ylabel('r')
legend({'corr z with channel-wise power', ...
    'corr z with SPoC component power (training data)', 'corr z with SPoC component power (test data)'}, ...
    'location','best')



% plot correlation pattern
subplot(rows,cols,9)
imagesc(reshape(r, [sqrt(Nx),sqrt(Nx)]))
axis square
title('channelwise power correlations')
colorbar

pattern = A(:,1);
[~, idx] = max(abs(pattern));
pattern = pattern./pattern(idx);
pattern_est = A_est(:,1);
[~, idx] = max(abs(pattern_est));
pattern_est = pattern_est./pattern_est(idx);


% plot SPoC pattern
subplot(rows,cols,11)
imagesc(reshape(pattern_est, [sqrt(Nx),sqrt(Nx)]))
axis square
title('SPoC component pattern')

% plot true target source pattern
subplot(rows,cols,12)
imagesc(reshape(pattern, [sqrt(Nx),sqrt(Nx)]))
axis square
title('SPoC component pattern')
