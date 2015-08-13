"""
    General description:
    The markers used for visual complexity feedback.
"""
class Marker():
    # preload completed
    preload_completed = 40
    
    # start video
    trial_start = 60
    
    # end of the trial (stimulus and cue vanish)
    trial_end = 65

    #markers for user action
    return_pressed = 1
    playback_paused_toggled = 2
    
    #markers for events in images
    child = 11
    cyclist = 12
    runner = 13
    #in case we find an unknown marker name
    generic_event = 19

    #modifier for events
    hazard = 20
    highlighted = 21
    from_left = 22
    from_right = 23
    
    # sync marker sent every 50th frame
    sync_50_frames = 50

    #trigger bbci online calculation (not used)
    classifier_trigger = 80
    
    # general markers
    feedback_initialized = 100
    state_changed_to_running = 110
    state_changed_to_paused = 119
    feedback_quit = 127
