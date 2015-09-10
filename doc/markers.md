#Markers

Definition of markers can be found in ``config/markers.ini``.
These definitions are used by both python and matlab code.

## Relation of optical marker and parallel/UDP marker

* optical markers are only displayed discrete timepoints (ticks) determined by the *screen_fps* config value -> during playback only displayed when a new image frame is drawn
* parallel and UDP data is sent at the same tick as the optomarker is drawn

## Collision handling of markers

###Problem
Multiple markers at the same frame

###Possible reasons

* technical marker (frame sync, seq start/end) at the same time as stimulus

## Feedback implementation
* 1:1 relation of feedback markers and optical markers (except special response case)
* markers are drawn/sent at the same tick as the screen update
* markers with lower values take precedence over markers with higher ones in the same frame
  => stimulus markers take precedence over technical markers (since they have lower values in ``marker.ini``)
* since technical markers can be lost, following additional procedure
    * the last frame in the standby state sends a ``pre_seq_start`` marker -> the next marker after that has always also ``seq_start`` semantics, even if it is a stimulus
* as long as ``Feedback.FPS >= 2 * config['screen_fps']``, the optomarker display is reset to black and hence the next frame should trigger an activation
	
### Special case: Feedback response markers
If response markers are generated in the feedback by Pyff (usually only during debugging), only the parallel/UDP marker is sent, no optical marker is drawn



## Matching/time correction of markers


### Questions
* how to handle  collisions unknown to the feedback (simultaneous parallel output both from button press and feedback )

TODO
