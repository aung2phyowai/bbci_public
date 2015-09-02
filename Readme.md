# Visual Complexity Observation

This repository contains experimental (Matlab and Python/Pyff) code to display image sequences.

## Steps to perform after checkout

All local configuration is performed in ``matlab/local_setup.m`` and, for the experiment run, the subject config is performed in ``matlab/experiment_scripts/subject_config.m``.
These file *need to be created* after checkout.
Examples can be found in [matlab/local_setup.m.example](matlab/local_setup.m.example). Adapt the content to your system's filepaths.
For the subject config, just copy [matlab/experiment_scripts/subject_config.m.example](matlab/experiment_scripts/subject_config.m.example).


## Run the experiments

The main file for running the experiment is [matlab/experiment_scripts/main_experiment.m](matlab/experiment_scripts/main_experiment.m). For testing [matlab/experiment_scripts/test_feedback.m](matlab/experiment_scripts/test_feedback.m) can be used.
Data can be found on the fileserver at ``/mnt/blbt-fs1/projects/visual_complexity/data/kitti/`` (your mountpoint may vary).
Additional information can be found in the corresponding [Experiment Readme](matlab/experiment_scripts/Readme.md)

## Image sequence files

Image sequences (as a video substitute) are defined in sequence files, which are text files containing a (relative) file path to each frame's image source.
Each line is of the following form.

```
${relativeFilePath}\t${optionalMarker1}\t${optionalMarkerN}
```

The file format can easily be created with, e.g., ``ls -1 ../original/2011_10_03_drive_0047_sync/image_02/data/*``

Relative paths are resolved relative to the sequence file's location (with the semantics of Python's ``os.path.join``).
Markers can either be integers or names of attributes in the [config/markers.ini](config/markers.ini) class.

More information on the editing process and naming conventions can be found under [Workflow Image Modification](doc/workflow_image_modification.md).
