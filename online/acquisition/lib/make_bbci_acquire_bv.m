function make_bbci_acquire_bv(debug, nouzz)

%%!!!!!!!!!!!!!!!!!!!!!
% Change the port number to 51234 in brainserver.h before making this file

try
    bbci_acquire_bv('close');
end
clear functions

if isunix
    params = {'../winunix/winthreads.c' '../winunix/winevents.c' '-lrt'};
else
    params = {'WS2_32.lib'};
end

params = ['bbci_acquire_bv.cpp' 'brainserver.c' 'headerfifo.c' params];

if nargin>= 1 && 1 == debug
  params = ['-g' '-v' params];
end

if nargin>=2 && 1 == nouzz
    params = ['-output' 'acquire_nouzz' '-DBV_PORT=32163' params];
end

params = ['-compatibleArrayDims' params];

mex(params{:})

disp('Build completed.')
