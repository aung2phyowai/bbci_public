#!/usr/bin/env python

# reaction_time.py -

""" Simple reaction time task """

import datetime
import logging
import os
import random

import markers
import pygame_helpers
from state_machine import StateMachineFeedback, StateOutput, FrameState

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
                             'min_readiness_duration' : 1.0,
                             'max_stimulus_jitter' : 2.0,
                             'block_length' : 5})

        return default_conf


class StandbyState(FrameState):
    def __init__(self, controller):
        super(StandbyState, self).__init__(controller)

    def _handle_state(self, screen):
        frame_markers = []
        #pygame_helpers.draw_center_cross(screen)
        self.logger.warn(markers.technical)
        if self._state_frame_count == 0:
            frame_markers.append(markers.technical['standby_start'])

        if "start_block" in self._unhandled_commands:
            self._unhandled_commands.remove('start_block')
            return StateOutput(frame_markers, SingleStimulusState(self.controller, 0))
        elif "show_crosshair" in self._unhandled_commands:
            self._unhandled_commands.remove("show_crosshair")
            return StateOutput(frame_markers, CrosshairState(self.controller))
        else:
            return StateOutput(frame_markers, self)


class SingleStimulusState(FrameState):
    def __init__(self, controller, stimulus_no):
        super(SingleStimulusState, self).__init__(controller)
        self.stimulus_no = stimulus_no
        conf = controller.config
        self._ready_start_frame_no = conf['inter_stimulus_delay'] * conf['screen_fps']
        min_stimulus_frame_no = self._ready_start_frame_no + conf['min_readiness_duration'] * conf['screen_fps']
        max_stimulus_frame_no = min_stimulus_frame_no + conf['max_stimulus_jitter'] * conf['screen_fps']
        self._stimulus_start_frame_no = random.randint(min_stimulus_frame_no, max_stimulus_frame_no)
        self._state_end_frame_no = self._stimulus_start_frame_no + conf['max_reaction_time'] * conf['screen_fps']
        self.logger.info("ready start frame %d, stimulus start frame %d",
                         self._ready_start_frame_no,
                         self._stimulus_start_frame_no)
        rt_filepath = os.path.join(conf['log_dir'],
                                   '_'.join([conf['start_date_string'],
                                             conf['log_prefix'],
                                             'reaction_time_params']) + ".log")
        with open(rt_filepath, 'a') as rt_file:
            line = [datetime.datetime.now().isoformat(),
                    str(conf['min_readiness_duration']),
                    str(conf['max_stimulus_jitter']),
                    str(conf['inter_stimulus_delay']),
                    str(1.0 * self._stimulus_start_frame_no / conf['screen_fps'])]
            rt_file.write('\t'.join(line) + '\n')


    def _handle_state(self, screen):
        frame_markers = []
        if self._state_frame_count < self._ready_start_frame_no:
            if self._state_frame_count == 0:
                frame_markers.append(markers.technical['seq_start'])
            pygame_helpers.draw_center_cross(screen)
        elif self._state_frame_count < self._stimulus_start_frame_no:
            pygame_helpers.draw_center_cross(screen, color=(200, 200, 200))
        else:
            if self._state_frame_count == self._stimulus_start_frame_no:
                frame_markers.append(markers.stimuli['generic_stimulus'])
            pygame_helpers.draw_abstract_stimulus(screen, color=(255, 255, 255))

        if self._state_frame_count < self._state_end_frame_no:
            return StateOutput(frame_markers, self)
        else:
            if self.stimulus_no + 1 < self.controller.config['block_length']:
                return StateOutput(frame_markers, SingleStimulusState(self.controller, self.stimulus_no + 1))
            else:
                return StateOutput(frame_markers, StandbyState(self.controller))

            
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
