# Visual Complexity Observation

This repository contains experimental (Matlab and Python/Pyff) code to display image sequences.

## Configuration

All local configuration is performed in ``experiment_scripts/local_setup.m``.
This file *needs to be created* after checkout.
An example can be found in ``experiment_scripts/local_setup.m.example``.

## Image sequence files

Image sequences (as a video substitute) are defined in sequence files, which are text files containing a (relative) file path to each frame's image source.
Each line has a format that are of the form

```
${relativeFileName}\t${optionalMarker1}\t${optionalMarkerN}
```

The file format can easily be created with, e.g., ``ls -1 ../original/2011_10_03_drive_0047_sync/image_02/data/*``

Relative paths are resolved relative to the sequence file's location (with the semantics of Python's os.path.join).
Markers can either be integers or names of attributes in the ``feedbacks/Marker.py`` class.
