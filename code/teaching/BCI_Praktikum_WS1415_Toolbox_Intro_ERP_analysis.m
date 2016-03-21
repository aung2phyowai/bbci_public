% ========================================================= 
% Goal of this Toolbox course: Event Related Potential(ERP) 
% data analysis, in more detail:
% (1) Loading data (from BrainVision data format) 
% (2) Getting to know the data structure
% (3) Preprocessing
% (3.1) Frequency filtering
% (3.2) Class definition/ Segmentation
% (3.3) Rejecting artifacts 
% (4) Visualization of temporal EEG data
% (5) Visualization of temporal/spatial ERP structure
% (6) Classification of ERP data (target vs. non-target) 
% ========================================================= 

%% Inspection of the raw data
% The raw data are saved in a BrainProducts file format consisting of three 
% files per measurement (.eeg, .vmrk, .vhdr).
% Short description of the three files: 
% .eeg: binary file containing recorded EEG + additional channels
% .vrmk: raw marker file containing all recorded markers
% .vhdr: header file with setup information (e.g. sampling frequency,
% impednaces of the channels, channel labels etc.)
% (using an Editor to have a look at them) 

%% Paradigm description
% The acquired data were gained during an auditory paradigm. (More
% information see the slides!)
% The sampling frequency was 1000 Hz, 64 channels were recorded.

% Variable für den Filenamen  
VP = 'VPpap_14_06_05';

file_name = fullfile(VP,'DirectionMarker/Block1-3/','/OnlineTrainFile*')

%% Setting the BBCI toolbox path

% set_localpaths();
addpath('/home/andreas/git/bbci_fork');

startup_bbci_toolbox('DataDir','/home/andreas/data/bbciRaw','MatDir','/home/andreas/data/bbciMat',...
     'TmpDir','/home/andreas/data/tmp');

%% (1) Load EEG data
% The function file_readBV takes the data directory as an input (here: 
% file_name). The return values are: 
% cnt - Continuous EEG data 
% hdr - Parameters of the EEG recording (sampling frequency, units etc.)
% mrk - Markers describing the time course of the experiment by tagging all
% events

% if you just want to know parameters of the experiment, loading just the
% header is faster
[hdr] = file_readBVheader(file_name)

hdr

[cnt, mrk_orig] = file_readBV(file_name);
% hdr.fs contains the sampling frequency 

%% (2) Closer look at the cnt-struct

cnt
% cnt.clab shows the labels of the recorded EEG channels 
% cnt.fs denotes the sampling frequency
% cnt.t shows the time points of the data points
% cnt.x contains the measured potentials (size: number of time points x number of channels)

% Plot the firt 1000 samples of one raw channel of the EEG (Cz) 
idx = util_chanind(cnt, 'Cz') 
figure, plot(cnt.x(1:1000,util_chanind(cnt,idx))) 
grid on
xlabel('Time [samples]')
ylabel('Potential [µVolt]')
legend('Cz')
title('Raw EEG Channel')


%% (3.1) Frequency filtering and subsampling

% Parameters for the frequency filter and sample frequency
filter_par = [0.2 0.7 20 23]; % [f_lowStop f_lowPass f_highPass f_highStop]

% Bandpass filtering

% First low pass
[n,Ws] = cheb2ord(filter_par(3)/hdr.fs*2,(filter_par(4))/hdr.fs*2,3,20);
[filt.b, filt.a]= cheby2(n, 20, Ws);
cntaux = proc_channelwise(cnt,'filtfilt',filt.b,filt.a);

% Plot the firt 1000 samples of one raw channel of the EEG (Cz) 
idx = util_chanind(cnt, 'Cz') 
figure, plot(cntaux.x(1:1000,(cnt,idx))) 
grid on
xlabel('Time [samples]')
ylabel('Potential [µVolt]')
legend('Cz')
title('Low-pass filtered EEG Channel')


% Subsample
fs = 100; % Target sample frequency
[cntaux, mrk_orig ] = proc_resample(cntaux,fs,'mrk',mrk_orig);

% High pass
[n,Ws] = cheb2ord(filter_par(2)/cntaux.fs*2,(filter_par(1))/cntaux.fs*2,3,20);
[filt.b, filt.a]= cheby2(n, 20, Ws,'high');
cntaux = proc_filtfilt(cntaux,filt.b,filt.a);

% notch filtering (only makes sense if sample frequency larger than 100 Hz)
% Also if the bandpass filtering performed above did not already filtered
% out the 50Hz noise
% if cntaux.fs > 100
%     notchWidth = 3; %width of the notch-filter around 50 Hz
%     [filt.b, filt.a]= cheby2(7, 30, [(50-notchWidth/2) (50+notchWidth/2)]/(cntaux.fs/2),'stop');
%     cntaux = proc_channelwise(cntaux,'filtfilt',filt.b,filt.a);
% end
cnt = cntaux;

idx = util_chanind(cnt, 'Cz')
figure, plot(cnt.x(1:1000,util_chanind(cnt,idx))) 
grid on
xlabel('Time [samples]')
ylabel('Potential [µVolt]')
legend('Cz')
title('Bandpass-filtered EEG Channel')

%% (3.2) Markers and class definitions, Segmentation

% The marker structure describes the exact course of events within an
% experiment.
% e.g. marker '11' encodes a target stimulus from the front right speaker

mrk_orig

% Assigning classes to the markers
mrk = mrk_defineClasses(mrk_orig, {11:16, 1:6; 'targets', 'non-targets'})

% Visualization which markers are used in the experiment
figure, hist(mrk_orig.event.desc, [1:1:255]), title('Count of each marker')

% proc_segmentation cuts the continuous data into small time windows, called
% epochs. Input: continuous signals (cnt), marker file containing all the
% time stamps of events, time window relative to the event

epo = proc_segmentation(cnt, mrk, [-150 800])

mnt =  mnt_setElectrodePositions(epo.clab)
mnt_grid= mnt_setGrid(mnt, 'small')

%% (4) Visualization of clean EEG data (unepoched) / Selection of channels

% Selecting specific EEG channels
find(strcmp('Cz', cnt.clab)) 

cnt.clab(18) 

util_chanind(cnt, 'Cz','C4') 
cnt.clab(ans)

util_chanind(cnt, 'C3,z,4') 
cnt.clab(ans)

util_chanind(cnt, 'C#') 
cnt.clab(ans)

% F3,z,4 states that we are looking for F3, Fz and F4  
% C# states that we are looking for the row of C-channels
% P* extracts all channels containing a P in their name
util_chanind(cnt, 'F3,z,4', 'C#', 'P*') 

% Plotting EEG time series

% plotting the channel Cz (#31) for the sample points 1 - 1000 
idx = util_chanind(cnt,'Cz')
figure, plot(cnt.x(1:1000,util_chanind(cnt,idx))) 
xlabel('Time [samples]')
ylabel('Potential [µVolt]')
legend('Cz')

% plotting Fz, Cz and Pz for the time point 1:1000
chan = {'Fz','Cz','Pz'};
figure,plot(cnt.x(1:1000,util_chanind(cnt,chan))) 
xlabel('Time [ms]')
ylabel('Potential [µVolt]')
legend(chan)


%% (5) Plot the temporal/spatial ERP data (epoched)

% plot just the first target epoch of channel Cz
idx_t= find(epo.y(1,:))
idx_Cz = strmatch('Cz', cnt.clab)

figure, plot(epo.t, epo.x(:,idx_Cz,idx_t(1))) 
title('Channel Cz, first target epoch'); 
xlabel('Time [ms]') ; ylabel('Potential [µVolt]')

% plot epochs for first 40 non-target epochs
idx_nt= find(epo.y(2,:)); 
figure, plot(epo.t, squeeze(epo.x(:,idx_Cz,idx_t(1:40))))
title('Channel Cz, first 40 non target epochs'); 
xlabel('Time [ms]') ; ylabel('Potential [µVolt]')

% plot average for all target epochs
figure,plot(epo.t, mean(epo.x(:,idx_Cz,idx_t),3)); 
hold on; 
% die durchschnittliche Wert für alle non-Targets plotten 
plot(epo.t, mean(epo.x(:,idx_Cz,idx_nt),3),'Color','k');
legend({'target','non-target'})

%%% Show raw ERPs
% Epochs w/o baselining and w/o artifact rejection
figure, grid_plot(epo, mnt_grid, struct('YUnit','µV'))
% grid_plot plots target and non-target ERPs averaging over all epochs and
% displaying a certain set of electrodes

% Further plotting functions
help visualization


%% (3.3) Artifact rejection

epo

% Select only eeg channels (leave out EOG, for example)
epo = proc_selectChannels(epo, util_scalpChannels())

% Baselining
epo = proc_baseline(epo, [-150,0]);

% Epochs with baselining and w/o artifact rejection
figure, grid_plot(epo, mnt_grid, struct('YUnit','µV'))

%% Looking for artifacts:
% 1) Min-Max criterion
[~, iArte] = proc_rejectArtifactsMaxMin(epo, 70, 'CLab', {'F9', 'F10', 'Fp1', 'Fp2',  'AF3', 'AF4'})

% 2) Variance criterion
[mrk, rclab, rtrials_var]= reject_varEventsAndChannels(cnt, mrk,...
        [-150 800]);

% Remove rejected epochs
epo = proc_selectEpochs(epo,'not',unique([iArte, rtrials_var]));

% Remove rejected Channels
epo = proc_selectChannels(epo,'not',rclab);

%% (5) Plot the temporal/spatial ERP data (epoched)

% Epochs with baselining and with artifact rejection
figure, grid_plot(epo, mnt_grid, struct('YUnit','µV'))

% Now plot also the spatial distribution of potentials
ivals = [180 240; 290 390];
figure,
h = plot_scalpEvolutionPlusChannel(epo, mnt, {'Cz'}, ivals, struct('GlobalCLim',true));
str_Ntrials = sprintf('Targets:%u   Non-Targets:%u. Rejected:%u',sum(epo.y,2),length(unique([iArte, rtrials_var])))
set(h.channel.title,'string',str_Ntrials)

% plot_scalpEvolutionPlusChannel shows the ERP response of the channel Cz.
% In addition the scalp activity pattern is given for the shaded time
% intervals.
% NOTE: We are only looking at MEAN VALUES. How can we quantify noise? 
% -> How well are the two classes separable? 

% What can we observe?:
% - early negative component
% - nice P300 
% - SOA of 175ms is visible

%% (6) ERP classification

%% (6.1) Exploration of class discriminant features

% epo_r = proc_rSquareSigned(epo)
epo_auc = proc_aucValues(epo)
% AUC metric returns the separability of target vs. non-target

grid_plot(epo, mnt_grid, struct('YUnit','µV'))
grid_addBars(epo_auc);

%% (6.2) Explore discriminant time intervals
ivals = [200 280; 290 390];

figure,
plot_scoreMatrix(epo_auc, ivals)

% ivals = procutil_selectTimeIntervals(epo_auc);
% ivals = sort(ivals);


%% (6.3.1) Classification accuracy using all channels and One time interval
% -> Classification using only spatial information

len = 50;%in ms
step = len/2;
cc=0;sliding_loss = nan(1,length(0:step:epo.t(end)-len)); t_center = sliding_loss;
for t_start = 0:step:epo.t(end)-len %start of the sliding epoch
    cc=cc+1;
    fv = proc_flaten(proc_jumpingMeans(epo,[t_start t_start+len]));
    sliding_loss(cc) = crossvalidation(fv, @train_RLDAshrink, 'SampleFcn', {@sample_chronKFold, 5});
    t_center(cc) = t_start+len/2;    
end
avg_clsTemporal = mean(cc);
figure, plot(t_center, 1-sliding_loss), ylabel('Classification accuracy'), xlabel('Center of the time interval [ms]')

%% (6.3.2) Classification accuracy using all time intervals and One channel
% -> Classification using only temporal information

loss_per_chan = nan(1,length(epo.clab));
glob_ivals = [50:50:600; 100:50:650]'; 
for i_chan = 1:length(epo.clab) %for each channel
    epo_chan = proc_selectChannels(epo, i_chan);
    fv = proc_flaten(proc_jumpingMeans(epo_chan,glob_ivals));
    loss_per_chan(i_chan) = crossvalidation(fv, @train_RLDAshrink, 'SampleFcn', {@sample_chronKFold, 5});
end


figure; plot_scalp(mnt, 1-loss_per_chan, 'CLim', 'range')
title('Classification accuracy with each channel')

%% (6.4) Classification using Spatio-temporal features (defined ivals and all channels)

fv = proc_flaten(proc_jumpingMeans(epo, ivals));
% ivals = [200 280; 290 390];

% 2 time intervals x 63 channels => 126 features

% make a scatter plot of all data and 2 feature dimensions
fv_auc = proc_aucValues(fv)
[srt_r, ix_srt] = sort(fv_auc.x);
xdat = fv.x([ix_srt(1), ix_srt(end)],:);

% choose the two best class discriminative features
figure, plot(xdat(1,find(fv.y(2,:))), xdat(2,find(fv.y(2,:))), 'r.');
hold on, plot(xdat(1,find(fv.y(1,:))), xdat(2,find(fv.y(1,:))), 'ks');
legend(fv.className)
title('2D representation the data')

% C = trainClassifier(fv, @train_RLDAshrink);
myLoss = crossvalidation(fv, {@train_RLDAshrink}, 'LossFcn', @loss_rocArea)

cls_accuracy = (1-myLoss)*100
