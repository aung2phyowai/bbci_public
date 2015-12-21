function [ cnt_pp, mrk_pp ] = vco_preprocess( cnt, mrk_orig, preprocessing_config )
%VCO_PREPROCESS Summary of this function goes here
%   Detailed explanation goes here

%  disp('Lowpass filtering...')
%     Hlow = designfilt('lowpassiir','DesignMethod','ellip', ...
%         'PassbandFrequency',options.filter(3)/(hdr.fs/2),...
%         'StopbandFrequency',options.filter(4)/(hdr.fs/2), ...
%         'PassbandRipple',1,'StopbandAttenuation',30);
%     cntaux = cnt;
%     for n_channel = 1:size(cnt.x,2)
%         cntaux.x(:,n_channel) = filtfilt(Hlow,cnt.x(:,n_channel));
%     end


    
% First low pass
% [n,Ws] = cheb2ord(filter_par(3)/hdr.fs*2,(filter_par(4))/hdr.fs*2,3,20);
% [filt.b, filt.a]= cheby2(n, 20, Ws);
% cntaux = proc_channelwise(cnt,'filtfilt',filt.b,filt.a);
%     
% % Subsample
% [cntaux, mrk_orig ] = proc_resample(cntaux, preprocessing_config.target_fs, 'mrk', mrk_orig);
% 
% % High pass
% [n,Ws] = cheb2ord(filter_par(2)/cntaux.fs*2,(filter_par(1))/cntaux.fs*2,3,20);
% [filt.b, filt.a]= cheby2(n, 20, Ws,'high');
% cntaux = proc_filtfilt(cntaux,filt.b,filt.a);


% %% filter eeg channels (band-pass)
% %adapted from posner_analysis/fileio/posner_loadRaw.m
% cnt_eeg = proc_selectChannels(cnt,util_scalpChannels);
% fp = [options.filter]/(cnt_eeg.fs/2);
% if fp(2) > options.fs/2
%     fp(2) = options.fs/2;
%     error('Upper cut-off band of the frequency filter is greater than nyquist frequency')
% end
% if fp(2) < fp(1)
%     error('Upper cut-off band of the frequency filter is greater than lower cut-off band')
% end
% 
% filter_specs = fdesign.bandpass('N,F3db1,F3db2,Ap',20,fp(1),fp(2),1);
% d_filter = design(filter_specs,'cheby1');
% for idx_ch = 1:size(cnt_eeg.x,2)
%     x_eeg = filter(d_filter,cnt_eeg.x(:,idx_ch));
%     x_eeg = flipud(filter(d_filter,flipud(x_eeg)));
%     cnt_eeg.x(:,idx_ch) = x_eeg;
% end



% cache_mat_file = 

%TODO parameter validation

f_ny = cnt.fs / 2;

disp('Lowpass filtering...')
    Hlow = designfilt('lowpassiir','DesignMethod','ellip', ...
        'PassbandFrequency', preprocessing_config.lowpass.passband / f_ny,...
        'StopbandFrequency',preprocessing_config.lowpass.stopband / f_ny, ...
        'PassbandRipple',1,'StopbandAttenuation',30);
    cntaux = cnt;
    for n_channel = 1:size(cnt.x,2)
        cntaux.x(:,n_channel) = filtfilt(Hlow,cnt.x(:,n_channel));
    end
    
    disp('Subsampling...')
    [cntaux, mrk_pp] = proc_resample(cntaux, preprocessing_config.target_fs ,'mrk', mrk_orig);
    
    cnt_eeg = proc_selectChannels(cntaux, util_scalpChannels());      
    cnt_neeg = proc_selectChannels(cntaux, 'not',util_scalpChannels()); 
    clear cntaux
    
    disp('Highpass filtering...')
    Hhigh = designfilt('highpassiir','DesignMethod','ellip', ...
        'PassbandFrequency', preprocessing_config.highpass.passband/ f_ny,...
        'StopbandFrequency',preprocessing_config.highpass.stopband/ f_ny, ...
        'PassbandRipple',1,'StopbandAttenuation',30);
    
    for n_channel = 1:size(cnt_eeg.x,2)
        cnt_eeg.x(:,n_channel) = filtfilt(Hhigh,cnt_eeg.x(:,n_channel));
    end    
    
%     if options.notch
%         disp('Notch filtering...')
%         [filt.b, filt.a] = cheby2(7,30,[(50-options.notchWidth/2),...
%             (50+options.notchWidth/2)]/(cnt_eeg.fs/2),'stop');
%         cnt_eeg = proc_channelwise(cnt_eeg,'filtfilt',filt.b,filt.a);
%     end
    
    cnt_pp = proc_appendChannels(cnt_eeg,cnt_neeg);
      
  
%     cnt_pp_eeg = cnt_eeg;
%     cnt_pp_aux = cnt_neeg;
    disp('Finished preprocessing')
end

