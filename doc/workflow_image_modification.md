# Workflow for Image Modification

## Prerequisites

* Gimp animation package (Ubuntu package ``gimp-gap``)
* helpful to add ``tools`` subdirectory to path
* overlay material can be obtained from http://pictogram2.com

## Sequence generation

The script should be executed in the kitti directory

Example:
```
vco_createSeqFile.sh c10_8-weiherfeldb unmodified/complex/c10-2011_10_03_0027-weiherfeldb/ 3050 3250 true
```

create a new sequence (called ``c10_8-weiherfeldb``) from the folder ``unmodified/complex/c10-2011_10_03_0027-weiherfeldb``, using the frames 3050 to 3249 (!). The last parameter means, that fade-in and fade-out to a black screen will be performed

The images will be *linked* to the originals in the unmodified directory, only the faded versions will be actually created

## Gimp workflow for modifications

1. Open all frames that should be edited as one image with a layer for each frame

2. Save the image in a new subdirectory ``${sceneName}-${startFrameNo}-${modificationDesc}`` of the modified dir. The filename is identical to the subdirectory name

3. Create a new xcf file for each frame via ``Video->Split Image to Frames``. Use 4 digit suffixes

4. Mark the path along which the overlay should be moved.

5. Open ``Video->Move Path``
   Select the overlay and the relative position
   Shift-click on ``Grab Path``
   Edit the scaling of start and end point. Switch control points to make sure the scaling of the end point is safed
   Ctrl-click on ``Reset all Points`` to interpolate parameters between start and end point
   Preview with Anim Preview (e.g., scaling 100%, real exact object, 5fps)
   Apply with Ok

6. Post-process occlusions (switch frames via ``Video->Go to->Next Frame``)
   Original (unoccluded) overlays should be kept as fully transparent layers

7. Create PNGs with ``Video->Frames Convert...``

8. ``cd`` into the modified-subdirectory, execute ``vco_renameModifiedPngs.sh ${startFrameNo}``, which creates a renamed subdirectory

## Update sequence with modified frames

Make sure you have created the ``renamed``-subdirectories with correct frame numbering.
Execute in the kitti directory:
```
vco_updateSeq.sh c10_4-weiherfeldb-mod5-v22 combined/c10_4-weiherfeldb-mod4-v2 modified/c10_4-weiherfeldb-1101-runnerNoHazard/renamed
```

Create a new sequence (called c10_4-weiherfeldb-mod5-v22) from the sequence in ``combined/c10_4-weiherfeldb-mod4-v2`` based on the modifications in ``modified/c10_4-weiherfeldb-1101-runnerNoHazard/renamed``.

Be aware that the script *relies heavily on the naming conventions* from above. Especially the frame numbering must be identical.
A new sequence file is generated and, if one exists for the base sequence, markers are copied.
Additionally, a new marker (currently ``19``) is added at the start frame of each modification.
