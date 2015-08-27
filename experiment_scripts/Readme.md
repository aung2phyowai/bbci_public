# Experiment scripts
Matlab scripts for runnign the experiment
## How to run

Run ``main_experiment.m`` for a complete run.
On development machines, the feedback can be tested with ``test_pyff.m``.

## Settings

Settings are kept in two distinct (global) structures.
Read the [global Readme](../Readme.md) for *configuration after the checkout*.

### PROJECT_SETUP

The global ``PROJECT_SETUP`` struct is initialized by calling ``project_setup()``.
It contains basic system information such as local paths and initializes the bbci toolbox.

## EXPERIMENT_CONFIG

The second variable ``EXPERIMENT_CONFIG`` contains information relevant to the actual experiment, such as sequence files to be played etc.
Information regarding the experimental run is stored in ``subject_config.m`` and automatically integrated into the ``EXPERIMENT_CONFIG`` struct.
The struct is initialized by calling ``experiment_config()``.
