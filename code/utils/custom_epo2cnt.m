function [x_out] = custom_epo2cnt(x_in, varargin)
% [x_cnt] = custom_epo2cnt(x_epo)
%  transform epoched data to continuous data and viceversa
%
% Sebastian Castano
% jscastanoc@gmail.com
% 2015

options = propertylist2struct(varargin{:});
options =  set_defaults(options,...
    'Ne',[],...
    'Nt',[]);


if ndims(x_in) == 3 % conversion epo -> cnt
    [Nt, Nc, Ne] = size(x_in);
    x_out = zeros(Nt*Ne, Nc);
    for idx_ch = 1:Nc
        x_out(:,idx_ch) = reshape(squeeze(x_in(:,idx_ch,:)),[Nt*Ne, 1]);
    end
elseif ndims(x_in) == 2 % inverse conversion cnt -> epo
    Nc = size(x_in,2);
    if isempty(options.Ne) && isempty(options.Nt)
        error('Provide at least Ne (number of epochs) or Nt (number of time samples per epoch)')
    end
    if ~isempty(options.Ne)
        Nt = size(x_in,1)/options.Ne;
        Ne = options.Ne;
    elseif ~isempty(options.Nt)
        Ne = size(x_in,1)/options.Nt;
        Nt = options.Nt;
    end
    x_out = permute(reshape(x_in,Nt,Ne,Nc),[1 3 2]);
end


