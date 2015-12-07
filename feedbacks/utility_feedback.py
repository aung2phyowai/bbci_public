#!/usr/bin/env python

# utility_feedback.py -

""" Feedback for small helper screens """

import logging
import random

import markers
import pygame_helpers
from state_machine import StateMachineFeedback, StateOutput, FrameState

class UtilityFeedback(StateMachineFeedback):
    """ State machine for small helper screens"""
    
    def init(self):
        super(UtilityFeedback, self).init()

    def start_state(self):
        return StandbyState(self)

    def _build_default_configuration(self):
        default_conf = super(UtilityFeedback, self)._build_default_configuration()
        return default_conf

class StandbyState(FrameState):
    def __init__(self, controller):
        super(StandbyState, self).__init__(controller)

    def _handle_state(self, screen):
        frame_markers = []
        #pygame_helpers.draw_center_cross(screen)

        if self._state_frame_count == 0:
            frame_markers.append(markers.technical['standby_start'])

        if  "show_crosshair" in self._unhandled_commands:
            self._unhandled_commands.remove("show_crosshair")
            return StateOutput(frame_markers, CrosshairState(self.controller))
        elif "optomarker_loop" in self._unhandled_commands:
            self._unhandled_commands.remove("optomarker_loop")
            return StateOutput(frame_markers, OptomarkerLoopState(self.controller))
        else:
            return StateOutput(frame_markers, self)


class CrosshairState(FrameState):
    """dummy state that just draws cross
     used for example during eyes open recording"""
    def __init__(self, controller):
        super(CrosshairState, self).__init__(controller)

    def _handle_state(self, screen):
        pygame_helpers.draw_center_cross(screen)
        return StateOutput([], self)

class OptomarkerLoopState(FrameState):
    """dummy state that just sends a marker every 10 frames
     used for experimental setup"""
    def __init__(self, controller):
        super(OptomarkerLoopState, self).__init__(controller)

    def _handle_state(self, screen):
        frame_markers = []
        pygame_helpers.draw_center_cross(screen)
        #pygame_helpers.draw_optomarker(screen, True, self.controller.config)
        if self._state_frame_count % 10 == 0:
            frame_markers.append(markers.stimuli['generic_stimulus'])
        return StateOutput(frame_markers, self)