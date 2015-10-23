""" Base feedback for a Pygame state machine """

import collections
import datetime
import os
import pygame
import subprocess
import tempfile

from FeedbackBase.PygameFeedback import PygameFeedback


import markers
import pygame_helpers
import vco_utils

class StateMachineFeedback(PygameFeedback):
    """ Base class for Python feedbacks that can be implemented as state machines.
        After playback, the current state is called every 1/config['screen_fps'] seconds and able to refresh the screen (for display in the subsequent frame).
        Control signals and `state_command` interactions are relayed to the state by calling the handle_event message.
        Each state is an instance of FrameState.

       Subclasses should typically override the start_state() method and provide additional configuration by overriding the _build_default_configuration() method (and calling the parent implementation).

       Configuration values that are set by the feedback are converted to the type they have in default configuration.


       Possible pitfalls:
        - be aware that the frame-rate of the serve_state calls (e.g., playback) is set by config['screen_fps']. The attribute self.FPS inherited from PygameFeedback only specifies the background processing rate
    """

#pylint: disable=attribute-defined-outside-init
    def init(self):
        """ Init feedback """
        PygameFeedback.init(self)
        self.config = self._build_default_configuration()
        #vco_utils.setup_logging_handlers(self.logger.name, self.config)
        self._cur_state = self.start_state()
        self._next_marker_values = []
        self._reposition_window = True
        self.tick_counter = -1L #necessary to have a state update ready before the first screen update in tick()

    def start_state(self):
        """ start state of the feedback
            it also becomes the current state after receiving a stop command
        """
        return DefaultState(self)

    def _build_default_configuration(self):
        """ return all available configuration keys alongside default values
             subclasses need to add the values returned by superclass definitions
            be aware of the type of the argument since conversion of matlab params depends on this
        """
        try:
            git_rev_info = subprocess.check_output(["git log -1 --format='%H %cI %s'"],
                                                   shell=True,
                                                   cwd=os.path.dirname(__file__)).strip()
        except subprocess.CalledProcessError as cpe:
            self.logger.warning("could not get git revision, probably not installed or outside of repo: %s", cpe)
            git_rev_info = 'unknown'
        return {
            'screen_width' : 1400,
            'screen_height' : 600,
            'screen_position_x': 400,
            'screen_position_y': 400,
            'background_color' : pygame.Color('black'),
            'optomarker_enabled' : True,
            'optomarker_width' : 24,
            'display_debug_information' : False,
            'screen_fps': 10,
            'log_dir' : tempfile.gettempdir(),
            'log_prefix' : 'pyff_feedback',
            'start_date_string' : datetime.datetime.now().isoformat().replace(":", "-"),
            'git_revision_info' : git_rev_info
        }

    def tick(self):
        """this method is called 1/self.FPS seconds (self.FPS >= config['screen_fps'])
           every config['screen_fps'] the screen is updated based on the state
           the state update/transition is performed one tick before the actual display to reduce jitter
        """
        PygameFeedback.tick(self)
        ticks_per_frame = self.FPS / self.config['screen_fps']
        #processing that occurs every frame (do not rely on the elapsed time in between)
        self._flush_markers()

        if self.tick_counter % ticks_per_frame == 0:
            #screen update
            pygame.display.flip()
#            self.logger.debug("flip at tick %d", self.tick_counter)

        #preparation of next screen update
        if (self.tick_counter + 1) % ticks_per_frame == 0:
            output = self._cur_state.serve_state(self.screen)
            self._cur_state = output.next_state
            self._next_marker_values.extend(output.marker_values)


        self.tick_counter += 1

    def process_pygame_event(self, event):
        super(StateMachineFeedback, self).process_pygame_event(event)
        if (event.type == pygame.KEYDOWN and
            event.key in (pygame.K_RETURN, pygame.K_KP_ENTER)):
            self.send_marker(markers.interactions['button_pressed'])

    def _flush_markers(self):
        """selects the highest priority marker, sends it and draws optomarker """
        if self._next_marker_values:
            #lowest value -> highest priority
            marker_value = min(self._next_marker_values)
            if len(self._next_marker_values) > 1:
                self.logger.info("sending only marker %d out of %s", marker_value, self._next_marker_values)
            pygame_helpers.draw_optomarker(self.screen, True, self.config)
            self.send_marker(marker_value)
            self._next_marker_values = []
        else:
            pygame_helpers.draw_optomarker(self.screen, False, self.config)


    def on_control_event(self, data):
        self.logger.info("got control event %s", data)
        self._cur_state.handle_event('control', data)

    def on_interaction_event(self, data):
        #self.logger.debug("got interaction event %s", data)
        for name, value in data.items():
            if name == 'state_command':
                cmd_str = vco_utils.parse_matlab_char_array(value)
                self.logger.debug("state command %s ", cmd_str)
                self._cur_state.handle_event('command', cmd_str)
            else:
                self.logger.debug("new variable: %s -> %s", name, value)
                self._handle_config_param(name, value)

    def _handle_config_param(self, name, value):
        #add to configuration
        #look if it needs to be handled by the state or machine, otherwise to state
        #validate: fps should be multiple of playback_fps
        converted_value = value
        if name in self.config:
            old_value = self.config[name]
            if isinstance(old_value, str):
                if isinstance(value, list):
                    #assume, we have a char array from matlab
                    converted_value = vco_utils.parse_matlab_char_array(value)
                else:
                    converted_value = str(value)
            else:
                #must be comparable with isinstance AND construct construct object from (matlab) type
                expected_types = [bool, int, float, pygame.Color]
                found_type = False
                for cur_type in expected_types:
                    if isinstance(old_value, cur_type):
                        converted_value = cur_type(value)
                        found_type = True
                if not found_type:
                    self.logger.error("unknown type of config variable %s, (default %s), probably you should extend this function in your subclass", name, old_value)
            # elif isinstance(old_value, int):
            #     converted_value = int(value)
            # elif isinstance(old_value, float):
            #     converted_value = float(value)
            # elif isinstance(old_value, pygame.Color):
            #     converted_value = pygame.Color(value) #accepts tuples, names, rgba hex
            # elif isinstance(old_value, bool):
            #     converted_value = bool(value)
            # else:
                
        
            #semantic validation, but save anyway at the moment
            if name == 'screen_fps' and self.FPS % converted_value != 0:
                self.logger.error("cannot display the frame rate %d since feedback fps %d is not a multiple",
                                  converted_value, self.FPS)
        else:
            self.logger.error("unknown config key %s", name)
        #currently, we save all values despite of probable errors
        self.config[name] = converted_value

        #some special case handling
        if name.startswith("screen"):
            self._assure_window_position()

        if name == "log_prefix":
            vco_utils.setup_logging_handlers(self.logger.name, self.config)

    def _assure_window_position(self):
        """ updates pygame screen position and size based on config value"""
        self.screenSize = [self.config['screen_width'], self.config['screen_height']]
        self.screenPos = [self.config['screen_position_x'], self.config['screen_position_y']]
        self.logger.debug(self.screenPos)
        #self.quit_pygame()
        #self.init_pygame()
        #os.environ['SDL_VIDEO_WINDOW_POS'] = "%d,%d" % (self.screenPos[0],
        #                                                self.screenPos[1])
        #self.screen = pygame.display.set_mode((self.config['screen_width'],
        #                                           self.config['screen_height']),
        #                                           pygame.RESIZABLE)
    def on_stop(self):
        """leaves current state if stop is requested"""
        self._cur_state.handle_event('command', 'stop')
        super(StateMachineFeedback, self).on_stop()

    def on_quit(self):
        """ Handler after receiving quit signal"""
        #necessary to stop bbci from blocking
        self.send_marker(markers.technical['feedback_quit'])
        PygameFeedback.on_quit(self)


    def send_marker(self, data):
        """send marker both to parallel and to UDP"""
        self._unshown_marker = True
        self.send_parallel(data)
        try:
            self.send_udp(str(data))
        except AttributeError: #if we call the feedback directly and the port is not set
            self.logger.error("could not send UDP marker %s", data)


#return value for states
StateOutput = collections.namedtuple('StateOutput', ['marker_values', 'next_state'])

class FrameState(object):
    """ Class representing a state of the feedback (in the FSM sense)
        The transition is performed by the serve_state method
        Typical reasons for state changes are control signals and time.

        Subclasses should override _handle_state for updates in every frame.
        Outside signals are stored in the fields _unhandled_commands and _unhandled_controls
    """

    def __init__(self, controller):
        self.controller = controller
        self._state_frame_count = -1L
        self._stop_requested = False
        self.logger = controller.logger.getChild(self.__class__.__name__)
        self._unhandled_commands = []
        self._unhandled_controls = []

    def _handle_state(self, screen): #pylint: disable=unused-argument
        """method for drawing on screen, to be overridden
           background has already been painted
           screen contents should not be flipped
           return value is identical to serve_state"""
        return StateOutput([], self)

    def serve_state(self, screen):
        """updates the screen and returns next state
           screen content should not be flipped
           returns a named tuple of type StateOutput
        """
        if self._stop_requested:
            return StateOutput([], self.controller.start_state())
        self._state_frame_count += 1
        conf = self.controller.config
        screen.fill(conf['background_color'])
        if conf['display_debug_information']:
            pygame_helpers.display_message(screen, self.__class__.__name__,
                                           pos=(20, 20), size=20)
        if self._state_frame_count == 0:
            self.logger.info("entered state %s", self.__class__.__name__)
        #self.logger.debug("frame %d of state %s", self._state_frame_count,
        #                  self.__class__.__name__)
        return self._handle_state(screen)

    def handle_event(self, event_type, event):
        """called upon receiving control events, might be used to update internal state"""
        if event_type == 'command':
            if event == 'stop':
                self._stop_requested = True
            else:
                self._unhandled_commands.append(event)
        elif event_type == 'control':
            self._unhandled_controls.append(event)

class DefaultState(FrameState):
    """default dummy state that does nothing"""

    def __init__(self, controller):
        super(DefaultState, self).__init__(controller)
        #optionally perform additional initialization

    def _handle_state(self, screen):
        return StateOutput([], self)

