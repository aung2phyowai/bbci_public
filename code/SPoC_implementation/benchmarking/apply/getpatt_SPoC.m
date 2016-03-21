function [spatial_p] = getpatt_FIRSPoC(w,h,X,varargin)

options = propertylist2struct(varargin{:});


Hbandp = designfilt('bandpassfir','DesignMethod','Window', ...
    'FilterOrder',options.N_filt,...
    'CutoffFrequency1', options.fband(1),...
    'CutoffFrequency2', options.fband(2),...
    'SampleRate', options.fs);

[Te, Nc, Ne] = size(X);

X_cnt = permute(X,[1,3,2]);
X_cnt = reshape(X_cnt, [Te*Ne,Nc]);


% perform filtering on each channel
X_filt = zeros(size(X_cnt));
for n_channel = 1:Nc
    X_filt(:,n_channel) = filtfilt(Hbandp,X_cnt(:,n_channel));
end

Cxx = X_filt'*X_filt;
spatial_p = Cxx*w;


end

