# Iview
Toolbox to acquire SMI eye tracking data and integrate it with BV EEG data


## Running experiments

1. start "Iview Custom Setup" on notebook (shortcut on upper right of desktop)
2. Initialization and calibration from Matlab (lab computer)
```
iview_acquire_gaze('persistent_init');
cleaner = onCleanup(@() iview_acquire_gaze('persistent_close'));
if binary_question('Calibrate iView? (Y/N)')
  iview_calibrate()
end
```
3. hit space on the recording labtop to start calibration

## Setup

### Network setup

* separate network with 192.168.1 prefix
* recording machine (lab computer) 192.168.1.1
* iview notebook 192.168.1.2, gateway set as 192.168.1.1
