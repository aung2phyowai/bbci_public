"""
    General description:
    The markers used for visual complexity feedback.
"""
class Marker():
    # start video
    trial_start = 60
    
    # end of the trial (stimulus and cue vanish)
    trial_end = 65
    
    # general markers
    feedback_initialized = 100
    state_changed_to_running = 110
    state_changed_to_paused = 119
    feedback_quit = 127
