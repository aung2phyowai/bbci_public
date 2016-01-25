#!/usr/bin/env python

# reaction_time.py -

""" Simple reaction time task """

import datetime
import logging
import os
import random
import sys
import time

import markers
import pygame_helpers
from state_machine import StateMachineFeedback, StateOutput, FrameState
import vco_utils

class ReactionTimeFeedback(StateMachineFeedback):
    """ State machine for display of reaction time

       Standby <-+
         |       | block complete
         v       |
      SingleStimulusState<-+
         |                 |
         +-----------------+
    


    """

    def start_state(self):
        return StandbyState(self)

    def _build_default_configuration(self):
        default_conf = super(ReactionTimeFeedback, self)._build_default_configuration()
        default_conf.update({'max_reaction_time' : 2.0,
                             'inter_stimulus_delay' : 2.0,
                             'min_readiness_duration' : 3.0,
                             'median_readiness_duration' : 3.5,
                             'pre_start_marker_gap' : 1.0, #in seconds before and after pre-start marker
                             'block_length' : 5})

        return default_conf


class StandbyState(FrameState):
    def __init__(self, controller):
        super(StandbyState, self).__init__(controller)
        self._send_pre_start_marker_frame = sys.maxint
        self._block_start_frame = sys.maxint

    def _handle_state(self, screen):
        frame_markers = []
        #pygame_helpers.draw_center_cross(screen)
        if self._state_frame_count == 0:
            frame_markers.append(markers.technical['standby_start'])
        elif self._state_frame_count == self._send_pre_start_marker_frame:
            frame_markers.append(markers.technical['pre_start'])

        if "start_block" in self._unhandled_commands:
            conf = self.controller.config
            frame_gap = conf['pre_start_marker_gap'] * conf['screen_fps']
            self._send_pre_start_marker_frame = self._state_frame_count + frame_gap
            self._block_start_frame = self._send_pre_start_marker_frame + frame_gap
            self._unhandled_commands.remove('start_block')
        if self._state_frame_count == self._block_start_frame:
            return StateOutput(frame_markers, SingleStimulusState(self.controller, 0))
#        elif "show_crosshair" in self._unhandled_commands:
#            self._unhandled_commands.remove("show_crosshair")
#            return StateOutput(frame_markers, CrosshairState(self.controller))
        else:
            return StateOutput(frame_markers, self)


class SingleStimulusState(FrameState):
    def __init__(self, controller, stimulus_no):
        super(SingleStimulusState, self).__init__(controller)
        self.stimulus_no = stimulus_no
        conf = controller.config
        self._ready_start_frame_no = conf['inter_stimulus_delay'] * conf['screen_fps']
        self._ready_duration = vco_utils.draw_exp_time_delay(conf['min_readiness_duration'], conf['median_readiness_duration'])
        ready_frame_length = int(self._ready_duration * conf['screen_fps'] + 0.5)
        self._stimulus_start_frame_no = self._ready_start_frame_no + ready_frame_length
        self._state_end_frame_no = self._stimulus_start_frame_no + conf['max_reaction_time'] * conf['screen_fps']
        self._stimulus_start_tick = None
        self._first_reaction_tick = None
        self.logger.info("ready start frame %d, stimulus start frame %d",
                         self._ready_start_frame_no,
                         self._stimulus_start_frame_no)


    def _handle_state(self, screen):
        frame_markers = []
        if self._state_frame_count < self._ready_start_frame_no:
            if self._state_frame_count == 0:
                frame_markers.append(markers.technical['seq_start'])
            pygame_helpers.draw_center_cross(screen)
        elif self._state_frame_count < self._stimulus_start_frame_no:
            if self._state_frame_count == self._stimulus_start_frame_no:
                frame_markers.append(markers.technical['get_ready_start'])
            pygame_helpers.draw_center_cross(screen, color=(200, 200, 200))
        else:
            if self._state_frame_count == self._stimulus_start_frame_no:
                frame_markers.append(markers.stimuli['generic_stimulus'])
                self._stimulus_start_tick = time.time()
                self._first_reaction_tick = None
            pygame_helpers.draw_abstract_stimulus(screen, color=(255, 255, 255))

        if self._state_frame_count < self._state_end_frame_no:
            return StateOutput(frame_markers, self)
        else:
            #log data
            conf = self.controller.config
            rt_filepath = os.path.join(conf['log_dir'],
                                       '_'.join([conf['start_date_string'],
                                                 conf['log_prefix'],
                                                 'reaction_time_params']) + ".log")
            if self._stimulus_start_tick is None or self._first_reaction_tick is None:
                reaction_time = float('nan')
            else:
                reaction_time = self._first_reaction_tick - self._stimulus_start_tick
            with open(rt_filepath, 'a') as rt_file:
                line = [datetime.datetime.now().isoformat(),
                        str(self.stimulus_no),
                        str(conf['min_readiness_duration']),
                        str(conf['median_readiness_duration']),
                        str(conf['inter_stimulus_delay']),
                        str(self._ready_duration),
                        str(reaction_time)]
                rt_file.write('\t'.join(line) + '\n')
            #followup state
            if self.stimulus_no + 1 < self.controller.config['block_length']:
                return StateOutput(frame_markers, SingleStimulusState(self.controller, self.stimulus_no + 1))
            else:
                return StateOutput(frame_markers, StandbyState(self.controller))

    def handle_event(self, event_type, event):
        if event_type == 'control':
            self.logger.info("control event at %1.4f",
                         time.time())
            if self._first_reaction_tick is None:
                self._first_reaction_tick = time.time()

def _run_standalone():
    logging.getLogger().addHandler(logging.StreamHandler())
    logging.getLogger().setLevel(logging.INFO)
    feedback = ReactionTimeFeedback()
    feedback.on_init()
    feedback.udp_markers_host = '127.0.0.1'  #pylint: disable=attribute-defined-outside-init
    feedback.udp_markers_port = 12344 #pylint: disable=attribute-defined-outside-init
    feedback._cur_state = SingleStimulusState(feedback, 0)
    feedback.on_play()

if __name__ == "__main__":
    _run_standalone()
