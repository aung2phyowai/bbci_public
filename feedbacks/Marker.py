"""
    General description:
    The markers used for visual complexity feedback.
"""
class Marker():
    # start video
    trial_start = 60
    
    # end of the trial (stimulus and cue vanish)
    trial_end = 65

    # sync marker sent every 50th frame
    sync_50_frames = 50

    #trigger bbci online calculation (not used)
    classifier_trigger = 80
    
    # general markers
    feedback_initialized = 100
    state_changed_to_running = 110
    state_changed_to_paused = 119
    feedback_quit = 127
