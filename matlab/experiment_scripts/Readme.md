# Experiment scripts
Matlab scripts for running the experiment
## How to run

Run ``main_experiment.m`` for a complete run.
On development machines, the feedback can be tested with ``test_feedback.m``.

## Data
Data can be found on the fileserver at ``/mnt/blbt-fs1/projects/visual_complexity/data/kitti/``.
For reduced loading time, it might make sense to copy the image data to the local harddrive.
Be aware, that most files in the ``combined`` folder are only symbolic links to the originals.

For copying only selected sequences and replacing symbolic links with their target, the following two scripts can be used. Both scripts should be executed from the main kitti directory since they use hard-coded relative paths.

* [vco_copySequence.sh](../../shell/vco_copySequence.sh) copies data from a supplied sequence directory
* [vco_copySequencesFromFile.sh](../../shell/vco_copySequencesFromFile.sh) copies data from all sequences that are listed in a "sequence list file", such as [config/complex_seqs.txt](../../config/complex_seqs.txt).

## Settings

Settings are kept in two distinct (global) structures.
Read the [global Readme](../../Readme.md) for *configuration after the checkout*.

### PROJECT_SETUP

The global ``PROJECT_SETUP`` struct is initialized by calling ``init_experiment_setup()`` (which in turn calls ``project_setup()``).
It contains basic system information such as local paths and initializes the bbci toolbox.

### EXPERIMENT_CONFIG

The second variable ``EXPERIMENT_CONFIG`` contains information relevant to the actual experiment, such as sequence files to be played etc.
Information regarding the experimental run is stored in ``subject_config.m`` and automatically integrated into the ``EXPERIMENT_CONFIG`` struct.
The struct is initialized by calling ``experiment_config()``.
