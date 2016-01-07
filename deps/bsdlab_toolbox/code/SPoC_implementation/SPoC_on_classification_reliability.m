addpath(genpath('/home/andreas/projects/SPoC_implementation/SPoC_public'));
addpath('/home/andreas/git/bbci_public');
startup_bbci();

%% Load example EEG data: here it's a motor imagery paradigm
BTB.RawDir = '/home/andreas/data/demoRaw';
[cnt, mrk_orig, hdr] = file_readBV('VPkg_08_08_07/calibration_motorimageryVPkg*', 'fs', 100);
% [cnt, mrk_orig, hdr] = file_readBV('VPtbj_08_10_16/calibration_motorimageryVPtbj*', 'fs', 100);
mrk = mrk_defineClasses(mrk_orig, {1, 2; 'Left', 'Right'});

%mnt = mnt_setElectrodePositions(cnt.clab);
%mnt= mnt_setGrid(mnt, 'medium');

%% choose parameters
band_bci = [10 12];
ival_erd= [-1000 6000];
% Artifact rejection based on variance criterion
mrk= reject_varEventsAndChannels(cnt, mrk, ival_erd, ...
                                 'DoBandpass', 1, ...
                                 'Verbose', 1);
% Bandpass to the frequency band of interest
[b,a]= butter(5, band_bci/cnt.fs*2); %freq. band normalized by Nyquist frequency
cnt_flt= proc_filt(cnt, b, a);
epo= proc_segmentation(cnt_flt, mrk, ival_erd);
erd= proc_envelope(epo, 'MovAvgMsec', 200);
erd= proc_baseline(erd, [-1000 0], 'trialwise', 0);

%% Determine classification reliability as target variable z

% cls_ival = [2000 4000];
cls_ival = [1000 4000]; % defining the temporal feature
fv = proc_selectIval(epo, cls_ival);  %fv_ival contains the cls_ival from all epochs
fv = proc_variance(fv);
%C = trainClassifier(fv,@train_RLDAshrink); %trains the classifier on all the data
fv = proc_flaten(fv); %removes unused dimension of fv.x
C = train_RLDAshrink(fv.x, fv.y,'StoreMeans',1); 
C_sca = train_RLDAshrink(fv.x, fv.y,'StoreMeans',1,'Scaling',1);

%mutil_1 = dot(C.w,C.mean(:,1)); % projected mean value of class 1 => negative value in projected space
%mutil_2 = dot(C.w,C.mean(:,2)); % projected mean value of class 2

Out = applyClassifier(fv, @train_RLDAshrink, C);
Out_sca = applyClassifier(fv, @train_RLDAshrink, C_sca);
%if Out values are <0, the trial is classified as class 1 otherwise as class 2

% D = Out/norm(C.w'); % normalization returns distance of each data point from the separating hyperplane
% R = D;
% ind = find(fv.y(1,:));
% R(ind) = (-1)*R(ind); %for reliability score change sign of classifier output of class 1
R_sca = Out_sca;
ind = find(fv.y(1,:));
R_sca(ind) = (-1)*R_sca(ind); %for reliability score change sign of classifier output of class 1

pos = find(sign(R_sca)==1); % returns indices of trials with positive reliability score
cls_acc = size(pos,2)/size(R_sca,2); % classification accuracy
z = R_sca; % using the classification reliability as target variable z 

plot(R_sca,'b--d')
xlabel('trial #')
ylabel('classification reliability')


%% apply SPoC on the classification reliability 
% straightforward approach to compute SPoC filter on all data, spoc() is
% based on the covariance approach
[W,A_est,lambda] = spoc(epo.x,z);

figure
bar(lambda)
title('eigenvalue spectrum')
ylabel('eigenvalue \lambda_i')
xlabel('SPoC component')
xlim([0 length(lambda)+1])

% more powerful framework: apply SPoC and do cross-validation for
% determinating the filter W
band = [9 12];
opt = struct;
opt.spoc_type = 'r2'; % here the SPoC type can be specified, possibilities: 'r2','lambda'
opt.n_components = 3; 
if isequal(opt.spoc_type,'r2')
    opt.n_components = 1;
end
opt.n_folds = 5; % number of cross-validation folds
[xval_corr, out] = bandpower_regression_with_SPoC(cnt_flt, mrk, ival_erd, band, z, opt);

% plot the results
figure
bar(xval_corr)
title('Correlation values for cross-validation')
ylabel('correlation')
xlabel('subfold #')
xlim([0 length(xval_corr)+1])

figure
plot(1:length(z),z,1:length(z),out.z_est)
title('Comparison of estimated target variable and the real one')
ylabel('target variable')
xlabel('epoch #')
legend('z','estimated z')

%% apply SSD decomposition before SPoC
opt_ssd = struct;
opt_ssd.band=[9 12];
[cnt_ssd, W, A, score, C_s]= proc_ssd(cnt, opt_ssd);
epo_ssd = proc_segmentation(cnt_ssd, mrk, ival_erd);

[W,A_est,lambda_ssd] = spoc(epo_ssd.x,R_sca);
