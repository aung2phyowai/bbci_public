function [spatial_p] = getpatt_FIRSPoC(w,h,X,method_params)
[Te, Nc, Ne] = size(X);

X_cnt = permute(X,[1,3,2]);
X_cnt = reshape(X_cnt, [Te*Ne,Nc]);

X_filt = zeros(size(X_cnt));
for n_channel = 1:size(X,2)
    X_filt(:,n_channel) = conv(X_cnt(:,n_channel), h,'same');
end
Cxx = X_filt'*X_filt;
spatial_p = Cxx*w;


end

