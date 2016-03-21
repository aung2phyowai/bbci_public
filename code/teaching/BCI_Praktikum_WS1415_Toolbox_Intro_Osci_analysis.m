% ========================================================= 
% Goal of this Toolbox course: Analysis of a motor imagery (MI) 
% experiment, in more detail:
% (1) Loading data 
% (2) Spectral inspection of continuous data
% (3) Preprocessing (filtering, artifact rejection, etc)
% (4) Spectral inspection of epoched data
% (5) Feature Inspection/Selection
% (6) Classification of ERD/ERS (left vs. right) 
% ========================================================= 

%% Paradigm description
% Subject was instructed to perform left hand, right hand or food MI 
% according to letter cues on the screen (approx. every 6s)
% The sampling frequency was 1000 Hz, 64 channels were recorded.

%% Setting up the toolbox
addpath('~/libraries/bbci_public');
% 
% startup_bbci_toolbox('DataDir','/home/andreas/data/demoRaw','MatDir','/home/andreas/data/demoMat',...
%      'TmpDir','/home/andreas/data/tmp');
startup_bbci_toolbox('DataDir','/mnt/data/tutorial_data/demoRaw','MatDir','/mnt/data/bbciMat/')

%% (1) Loading the data 

[cnt, mrk_orig, hdr] = file_readBV('VPkg_08_08_07/calibration_motorimageryVPkg*', 'fs', 100);

hist(mrk_orig.event.desc,255) %Histogram of the markers
unique(mrk_orig.event.desc) %returns the markers with no repetitions

%% (1) Extract markers
mrk = mrk_defineClasses(mrk_orig, {1, 2; 'Left', 'Right'});

%% (2) Compute spectrum
% As ERD effects are best visible in an approximately chosen frequency band, 
% look at the spectrum first. Calculate it for every epoch in the broad band 
% from 1 to 40 Hz. Don't use rectangular window for FFT (default), but rather 
% e.g. kaiser window with better characteristics. Window needs information 
% about lenght / sample resolution contained in cnt.fs 
spec_cnt = proc_spectrum(cnt, [1 40], kaiser(cnt.fs,2));
grid on

% By default, windows are selected with half-window overlap. 
% Pitfall: If windows don't fit the epoch length, the last interval of your data might NOT be analyzed!
% plots the spectrum of all 50 channels; 
plot(spec_cnt.t,spec_cnt.x)
spec_cnt = proc_selectChannels(spec_cnt, {'C3', 'Cz', 'C4', 'POz','Pz','F5'}); %select channels
figure, plot(spec_cnt.t, spec_cnt.x), 
legend(spec_cnt.clab)

% Homework: plot spectrum of cnt after laplace filtering

% What is the basic shape of an EEG spectrum? 
% What may be causes for derivations from this average shape?
% What has happened with channel F5?

%% (3) High-variance channels may be positioned on the outer regions of the scalp. Muscles have a stronger influence there. 
% It may be good to reject them from the analysis.
% Visualize the variance per trial and per channel in a 2D plot
[mrk_clean,  rClab, rTrials]= reject_varEventsAndChannels(cnt, mrk, [-1000 4500],...
                'visualize',1,...
                'verbose',1);
mrk
mrk_clean
rClab
cnt= proc_selectChannels(cnt, 'not',rClab);
mrk = mrk_clean;

%% (4) Cut out epochs from continuous data
ival_erd = [2000 4500];
epo_nofilt = proc_segmentation(cnt, mrk, ival_erd); %choosing the time window relativ to the marker 
spec_epo = proc_spectrum(epo_nofilt, [1 40]); %only this frequency band is really interesting to use at the moment
figure,
plot_channel(spec_epo, {'C3', 'C4'})

%%% Hier schon mal Laplace??

%% (4) Investigate spectrum
mnt = mnt_setElectrodePositions(cnt.clab);
mnt= mnt_setGrid(mnt, 'medium');

colOrder= [245 159 0; 0 150 200]/255;
opt_grid_spec= defopt_spec('xTickAxes','CPz', ...
                           'colorOrder',colOrder);
                       
fig_set(2);
H=grid_plot(spec_epo, mnt, opt_grid_spec) %plots the spectrum

% Plot AUC-values in addition
epo_auc_spec = proc_aucValues(spec_epo);
grid_addBars(epo_auc_spec,'hscale',H.scale)

% Problem: small sample size makes AUC values VERY noisy. In such cases,
% r-square values may be more informative
epo_r_spec = proc_rSquareSigned(spec_epo);
grid_addBars(epo_r_spec,'hscale',H.scale);


% Alternatively: scalp plots for several frequency bands
band_list= [6 8; 9 13; 14 16; 17 23; 25 30];

fig_set(3);
H= plot_scalpEvolutionPlusChannel(spec_epo, mnt, 'C3', band_list, ...
                             defopt_scalp_power, ...
                             'ColorOrder',colOrder, ...
                             'ScalePos','vert', ...
                             'GlobalCLim',0,...
                             'ExtrapolateToMean', 1,...
                             'XUnit', spec_epo.xUnit, 'YUnit', spec_epo.yUnit);

% choose a freq band based on spectrum plot
band_bci = [9 13];

%% (5) Band-pass filter the cnt data (NOT the epo data!) to the selected band
[b,a]= butter(5, band_bci/cnt.fs*2);
cnt_flt= proc_filt(cnt, b, a);

% Check the spectrum again
spec_cnt_flt = proc_spectrum(cnt_flt, [1 40]);
figure,
plot(spec_cnt_flt.t,spec_cnt_flt.x) %plots the filtered spectrum of all 50 channels
grid on

% Compute event related desynchronization (ERD)
epo_filt = proc_segmentation(cnt_flt,mrk,[-1000,6000]); %segmentation for filtered data
erd = proc_envelope(epo_filt,'MovAvgMsec', 200); %compute envelope for bandpass-filtered epoched data
erd_auc = proc_rSquareSigned(erd);

% As for ERP, a base line correction may be helpful necessary. 
erd_bl = proc_baseline(erd,[-1000,0],'trialwise',0); %baseline correction refering to pre-trail data
erd_auc_bl = proc_rSquareSigned(erd_bl); %compute signed r^2 value as measure for discriminance

% Laplace filtering
epo_lap= proc_laplacian(epo_filt,'verbose',1);
erd_lap = proc_envelope(epo_lap,'MovAvgMsec', 200); %compute envelope for bandpass-filtered epoched data
erd_auc_lap = proc_rSquareSigned(erd_lap);

% ERD grid plot without baselining
fig_set(4);
H1 = grid_plot(erd,mnt,defopt_erps,'YUnit', spec_epo.yUnit);
grid_addBars(erd_auc,'HScale',H1.scale)


% ERD grid plot with baselining
fig_set(6);
H2 = grid_plot(erd_lap,mnt,defopt_erps,'YUnit', spec_epo.yUnit);
grid_addBars(erd_auc_lap,'HScale',H2.scale)


clab= {'C3','C4'};
H = plot_scalpEvolutionPlusChannel(erd_bl, mnt, clab,[1200,4500]);

% With finer temporal resolution
ival_scalps = 0:1000:5000;
fig_set(6);
plot_scalpEvolutionPlusChannel(erd_auc, mnt, clab, ival_scalps, ...
                    defopt_scalp_r, 'ExtrapolateToZero', 1);

% Visualize the separability of left vs. right 
fig_set(7);
plot_scoreMatrix(erd_auc, [0 1000; 1000 2000; 2000 3000; 3000 4000; 4000 5000])

% AUC/r-square score for Laplace filtered ERDs
fig_set(8);
plot_scoreMatrix(erd_auc_lap, [0 1000; 1000 2000; 2000 3000; 3000 4000; 4000 5000])

%% (6.1) Classification of Raw ERD
ival_cf=[1000 3750];
epo_filt = proc_segmentation(cnt_flt,mrk,ival_cf)
erd = proc_envelope(epo_filt,'MovAvgMsec', 200);
fv= proc_jumpingMeans(erd, ival_cf);
fv= proc_logarithm(fv)

[loss, lossem]= crossvalidation(fv, @train_RLDAshrink)
fprintf('Class. accuracy: %d\n', 1-loss);
% Remark: Discriminability between classes is weak. What's the problem? Maybe the subject was not suitable? 
% Maybe the analysis has a problem? This time it was in fact a "good" subject. Spatial smearing is the largest problem: neighboring channels nearly show the same signal. 
% Resolve this by applying a spatial filter BEFORE any non-linear transformation! First, we use the laplace filter on the time series data (NOT the spectra!)

%% (6.2) Classification of Laplace filtered data

% Laplace filter improves spatial contrast. Labels are not involved...
% epo_lap = proc_laplacian(epo_filt);
% erd_lap = proc_envelope(epo_lap); %compute envelope for bandpass-filtered epoched data
% fv_lap= proc_jumpingMeans(erd_lap, ival_cf);
% fv = proc_logarithm(fv_lap);
% 
%% This unfortunately turns out way too good. We need to omit it for
%% pedagogical reasons... :-)
% [loss, lossem]= crossvalidation(fv, @train_RLDAshrink)
% fprintf('Class. accuracy: %d\n', 1-loss);

%% (6.3) Classification of CSP filtered data
% However, laplace filters are fixed and not data dependent. We can do better than that, if we can design filters
% specifically for our data. Ideally, the filters are maximizing the contrast of ERD between classes...
% Input to CSP: bandpass-filtered epochs + labels
% SLIDES: Introduce CSP

[epo_csp, CSP_W, CSP_EIG, CSP_A]= proc_cspAuto(epo_filt,'selectPolicy','all');
figure, 
subplot(2,4,1); plot_scalp(mnt, CSP_W(:,1), 'ScalePos', 'none'), title(['filter ' epo_filt.className{1}])
subplot(2,4,2); plot_scalp(mnt, CSP_W(:,2), 'ScalePos', 'none'), title(['filter ' epo_filt.className{1}])
subplot(2,4,3); plot_scalp(mnt, CSP_W(:,end-1), 'ScalePos', 'none'), title(['filter ' epo_filt.className{2}])
subplot(2,4,4); plot_scalp(mnt, CSP_W(:,end), 'ScalePos', 'none'), title(['filter ' epo_filt.className{2}])


subplot(2,4,5); plot_scalp(mnt, CSP_A(1,:), 'ScalePos', 'none'), title(['pattern ' epo_filt.className{1}])
subplot(2,4,6); plot_scalp(mnt, CSP_A(2,:), 'ScalePos', 'none'), title(['pattern ' epo_filt.className{1}])
subplot(2,4,7); plot_scalp(mnt, CSP_A(end-1,:), 'ScalePos', 'none'), title(['pattern ' epo_filt.className{2}])
subplot(2,4,8); plot_scalp(mnt, CSP_A(end,:), 'ScalePos', 'none'), title(['pattern ' epo_filt.className{2}])

% Eigenvalues of CSP components may be informative for which ones and how
% many we should choose. Here: one from each end of the spectrum should be
% enough
figure
bar(CSP_EIG'); grid on ; xlabel('CSP component #'); ylabel('Eigenvalue');
[epo_csp, CSP_W, CSP_EIG, CSP_A]= proc_cspAuto(epo_filt,1);

erd_csp = proc_envelope(epo_csp);
fv_csp= proc_jumpingMeans(erd_csp, ival_cf);
fv = proc_logarithm(fv_csp);
[loss, lossem]= crossvalidation(fv, @train_RLDAshrink)
fprintf('Class. accuracy: %d\n', 1-loss);

%% (6.4) Classification of CSP filtered data (using a cross-validation scheme)
% Overfitting is a issue, though. CSP-filters are computed using labels. Thus me must test the filters on unseen data.
% Solution, do CSP within the cross-validation
proc.train= {{'CSPW', @proc_cspAuto, 1}
             @proc_envelope
             {@proc_jumpingMeans,ival_cf}
             @proc_logarithm
            };
proc.apply= {{@proc_linearDerivation, '$CSPW'}
             @proc_envelope
             {@proc_jumpingMeans,ival_cf}
             @proc_logarithm
            };

[loss, lossem]= crossvalidation(epo_filt, @train_RLDAshrink,'Proc', proc,'SampleFcn', {@sample_chronKFold, 5})
fprintf('Class. accuracy: %d\n', 1-loss);
