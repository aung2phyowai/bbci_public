# Experiment Setup

## Optical Marker

Settings of box:
* Signal Gain : 10
* Trigger Level: about 1.5


## Software Setup

### PNET

* download from http://www.mathworks.com/matlabcentral/fileexchange/345-tcp-udp-ip-toolbox-2-0-6
* compile mex (on Win 7) with ``>mex -O pnet.c "C:\Program Files\MATLAB\R2014b\sys\lcc64\lcc64\lib64\wsock32.lib" -DWIN32``
