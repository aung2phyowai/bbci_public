function dat = custom_spectrogram(dat, varargin)
% PROC_SPECTROGRAM -  calculates the spectrogram using the discrete
% gabor transformation 
%
%Usage:
%   dat = proc_spectrogram(dat, freq, <OPT>)
%   dat = proc_spectrogram(dat, freq, Window, <OPT>)
%   dat = proc_spectrogram(dat, freq, Window, NOverlap,<OPT>)
% 
%Arguments:
% DAT          - data structure of continuous or epoched data
%                which requires at least dat.fs, dat.x and dat.bandwidth   
% 
%   
% OPT - struct or property/value list of optional properties:
% 'CLab'     - specifies for which channels the spectrogram is calculated.
%              (default '*')
% 'Output'   - Determines if and how the FFT coefficients are processed.
%              'complex' preserves the complex output (with both phase and
%              amplitude information), 'amplitude' returns the absolute
%              value, 'power' the squared absolute value, 'db' log power, 
%              and 'phase' the phase in radians. Default 'complex'.
% 'dgt'      - Use custom values for "a" and "M" for the discrete 
%              gabor transform (dgt).
% 'doDownSampling' - Allow downsampling of the data to make the dgt faster
% 'sample_fs' - Use a custom sampling rate for downsampling if
%               'doDownSampling' is true.
%
%Returns:
% DAT    -    updated data structure with a higher dimension.
%             For continuous data, the dimensions correspond to 
%             time x frequency x channels. For epoched data, time x
%             frequency x channels x epochs.
%             The coefficients are complex. You can obtain the amplitude by
%             abs(dat.x), power by abs(dat.x).^2, and phase by
%             phase(dat.x);
%
% Note: Requires signal processing toolbox.
% ** TODO ** : DBSCALED is not implemented yet! 
%
% See also proc_wavelets, proc_spectrum

% Steven Lemm, Stefan Haufe, Matthias Treder, Berlin 2004, 2010

if ~(exist('ltfat','file')==7)
    warning(['The ltfat toolbox seems to be erronous or non-existent',... 
    'in the MATLAB path. \n The toolbox can be downloaded from http://ltfat.sourceforge.net/ ']);
    return
end    


misc_checkType(dat,'!STRUCT(x fs bandwidth)');

props = { 'DbScaled'             1                           '!BOOL';
         'CLab',                '*'                         'CHAR|CELL{CHAR}|DOUBLE[-]';
         'Output'               'complex'                   '!CHAR(complex amplitude power db phase)';
          'dgt'                 [3 dat.fs/2]                '!DOUBLE[2]' %default values for the dgt paramerts a and M ([a M])
          'doDownSampling'      1                       '!BOOL' % allow downsampling of the data based on the bandwidth and the current fs      
          'sample_fs'           100                    '!DOUBLE'; 
         };

if nargin==0,
  dat= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt,isdefault] = opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

[opt,isdefault] = opt_overrideIfDefault(opt,isdefault,'Window',floor(dat.fs/2));

dat = misc_history(dat);

%% Spectrogram
dat = proc_selectChannels(dat,opt.CLab);

% do downsampling and apply lowpass filter if necessary 
if opt.doDownSampling
    if(dat.fs > opt.sample_fs)
        
        if(dat.bandwidth(4) * 2 > opt.sample_fs )
            
            lowpass = [opt.sample_fs/2 - 1 opt.sample_fs/2];
            
            sz = size(dat.x);
            nChannels = sz(2);
            nTrials = sz(3) ;
            disp('Lowpass filtering...')
            Hlow = designfilt('lowpassiir','DesignMethod','ellip', ...
                'PassbandFrequency',lowpass(1)/(dat.fs/2),...
                'StopbandFrequency',lowpass(2)/(dat.fs/2), ...
                'PassbandRipple',1,'StopbandAttenuation',30);
            
            for ii = 1:nChannels
                for jj = 1:nTrials
                    dat.x (:,ii,jj) = filtfilt(Hlow,dat.x(:,ii,jj));
                end
            end
            dat.bandwidth(3:4) = lowpass;
        end
        disp('Subsampling...')
        
        dat = proc_resample(dat,opt.sample_fs);
        dat.fs = opt.sample_fs;
        
        %change the M-parameter of the dgt to
        % the now fs
        if(isdefault.dgt)
           opt.dgt(2) = dat.fs; 
        end    
    end
    
end


X = dat.x;
%reshape X (dim nsamples x nChannels x nTrials) to nsamples x
%[nChannels_1 nchannels_2 .. nchannels_nTrials]
% and divide the data in chunks to avoid memory problems
 sz = size(X);
 nSamples = sz(1);
 if(ndims(X) == 3)
     nChannels = sz(2);
     nTrials = sz(3);
     X = reshape(X, [nSamples nChannels*nTrials]);
     
     chunksize = 500; %
     nchunks = round(nChannels*nTrials/chunksize);
     chunks = round(linspace(0,nChannels*nTrials,nchunks));
     
     if(length(chunks)< 2)
         chunks = [0 nChannels*nTrials];
     end
 elseif(ndims(X) ==2 )
     nChannels = sz(2);
     
     chunksize = 25; %
     nchunks = round(nChannels/chunksize);
     chunks = round(linspace(0,nChannels,nchunks));
     if(length(chunks)< 2)
         chunks = [0 nChannels];
     end
 end
 
 
 
 a = opt.dgt(1);
M = opt.dgt(2);
S = [];

for kk = 1:length(chunks)-1
    [S_tmp,Ls] = dgtreal(X(:,chunks(kk)+1:chunks(kk+1)),'gauss',a,M);
    S = cat(3,S,S_tmp);
end
% calculate the ratio between the size of the zero-padding and the actual
% signal and only keep the actual transformed signal
L=dgtlength(Ls,a,M);
ratio = Ls/L;
ss = size(S);
ltransl = ss(2);
S = S(:,1:floor(ratio*ltransl),:,:);



clear X

S = permute(S,[2,1,3]);


% Reshape vector to matrix
ss = size(S);
if ndims(dat.x) == 3      
  dat.x = reshape(S,[ss(1) ss(2) nChannels nTrials]);
end

%adjust time domain;
n_t = ss(1);
t = dat.t; 
t_min = t(1);
t_max = t(end);
dat.t = linspace(t_min,t_max,n_t);

%adjust the fs
dat.fs = 1000* n_t/(t_max - t_min) ; %this is approximately sample_fs/a

dat.a = a;
dat.M = M;

switch(opt.Output)
  case 'complex'
    % do nothing
  case 'amplitude'
    dat.x = abs(dat.x);
    dat.yUnit= 'amplitude';
  case 'power'
    dat.x = abs(dat.x).^2;
    dat.yUnit= 'power';
  case 'db'
    dat.x = 10* log10( abs(dat.x).^2 );
    dat.yUnit= 'log power';
  case 'phase'
    dat.x = angle(dat.x);
    dat.yUnit= 'phase';
end


