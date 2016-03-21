function Cxxz = create_Cxxz(Cxxe, z)
% Creates the z-weighted covariance matrix from a time series of covariance
% matrices given in Cxxe 

N_e = size(Cxxe,3);
Z = zeros(size(Cxxe));
for e=1:N_e
    Z(:,:,e) = z(e); % assign z(e) to all entries of Z
end
Cxxz = sum(Cxxe.*Z , 3) ./ N_e; % calculate the expected value Cxxe*z over all epochs
