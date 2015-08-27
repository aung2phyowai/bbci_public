function markers = marker_definitions( )
%MARKER_DEFINITIONS Definition of marker codes

markers = struct;

%user interactions
markers.return_pressed = 1;
markers.playback_paused_toggled = 2;

%events
markers.child = 11;
markers.cyclist = 12;
markers.runner = 13;
markers.generic_event = 19;

%event modifiers
markers.hazard = 20;
markers.highlighted = 21;
markers.from_left = 22;
markers.from_right = 23;

%generic
markers.preload_completed = 40;
markers.trial_start = 60;
markers.trial_end = 65;
markers.sync_50_frames = 50;
markers.classifier_trigger = 80;

end

