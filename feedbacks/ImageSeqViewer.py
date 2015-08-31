#!/usr/bin/env python

# ImageSeqViewer.py -

"""Displays a ``video'' from a sequence of images."""


import os
import sys
import logging
import time
import datetime
import tempfile

import pygame

from FeedbackBase.PygameFeedback import PygameFeedback


import markers
import vco_utils

class ImageSeqViewer(PygameFeedback):
    """Feedback for playback of image sequences

       Images are read from ``sequence files'' that are of the form
         ${relativeFileName}\t${optionalMarker1}\t${optionalMarkerN}
        The file format can easily be created with, e.g.,
         `ls -1 ../original/2011_10_03_drive_0047_sync/image_02/data/*`
       Relative paths are resolved relative to the sequence file's
        location (semantics of os.path.join).
       Markers can either be integers or names of attributes in
        markers.py.

       If preload_images is true (as is the default), all images are
        loaded into memory at once.
    """

    def init(self):
        """ Init feedback """
        PygameFeedback.init(self)
        self.apply_default_settings()
        self.init_private_state()


    def init_private_state(self):
        """ init private state """
        self._state = 'standby'
        self._current_image_no = -1
        self._last_marker_seq_no = -1 - self.optomarker_frame_length
        self._start_date_string = datetime.datetime.now().isoformat().replace(":", "-")
        #explicit logger for sequences
        self._seq_logging_handler = None
        self._image_cache = {}
        self._image_seq = []
        self.current_seq_file = None

        #we have two handlers: one logs everything to temp dir
        # the second one logs per sequence in dir specified by parameter
        #set up the first one
        log_file_name = os.path.join(tempfile.gettempdir(),
                                     "image_seq_view_all_" + self._start_date_string + ".log")
        self.logger.debug("global logging to %s", log_file_name)
        self.logger.addHandler(logging.FileHandler(log_file_name))



    def apply_default_settings(self):
        """ init public state (typically partially overriden by Matlab) """
        self.caption = "Image Sequence Viewer"
        # use separate variables to avoid type conversions
        #  when interacting with Matlab
        self.screen_width = 1400
        self.screen_height = 600
        self.screen_position_x = 400
        self.screen_position_y = 400
        self.FPS = 10
        self.fullscreen = False #fullscreen seems to be broken
        self.preload_images = True
        self.use_optomarker = True
        #for how many frames should the marker be displayed
        self.optomarker_frame_length = 1
        self.logging_dir = tempfile.gettempdir()
        self.logging_prefix = 'image_seq_view'


    def on_interaction_event(self, data):
        # self.logger.info("got event: %s\n with type %s" % (data, type(data)))

        # workaround - actually a command, but those don't cause an interaction event
        if 'trigger_preload' in data:
            self.logger.info("triggering preload")
            self._preload()
        PygameFeedback.on_interaction_event(self, data)

    def on_control_event(self, data):
        #self.logger.info("got control event %s\n with type %s" % (data, type(data)))
        pass

    def pre_mainloop(self):
        """executed once after receiving play command"""
        self.screenSize = [int(self.screen_width), int(self.screen_height)] #pylint: disable=attribute-defined-outside-init
        self.screenPos = [self.screen_position_x, self.screen_position_y] #pylint: disable=attribute-defined-outside-init

        PygameFeedback.pre_mainloop(self)

        self._setup_seq_logger()
        pickle_file_name = os.path.join(self.logging_dir,
                                        self.logging_prefix + "_" + self._start_date_string + ".p")
        vco_utils.dump_settings(self, pickle_file_name)
        #trigger preload (if enabled)
        self._preload()
        self._state = 'playback'



    def _setup_seq_logger(self):
        """create new logger for the sequence based on settings"""
        logging_setup_changed = False
        #param_ members are set by matlab, so pylint should be disabled
        # setup logger if we get a new logging dir
        if  hasattr(self, 'param_logging_dir'): #pylint: disable=no-member
            new_logging_dir = vco_utils.parse_matlab_char_array(self.param_logging_dir)#pylint: disable=no-member
            if new_logging_dir != self.logging_dir:
                self.logging_dir = new_logging_dir
                logging_setup_changed = True
                if not os.path.exists(self.logging_dir):
                    os.makedirs(self.logging_dir)

        if hasattr(self, 'param_logging_prefix'): #pylint: disable=no-member
            new_logging_prefix = vco_utils.parse_matlab_char_array(self.param_logging_prefix) #pylint: disable=no-member
            if new_logging_prefix != self.logging_prefix:
                self.logging_prefix = new_logging_prefix
                logging_setup_changed = True

        # start logging per sequence
        if logging_setup_changed or self._seq_logging_handler is None:
            log_file_name = os.path.join(self.logging_dir,
                                         self.logging_prefix + "_" + self._start_date_string + ".log")
            if self._seq_logging_handler is not None:
                self.logger.removeHandler(self._seq_logging_handler)
            self.logger.debug("writing sequence log to %s", log_file_name)
            self._seq_logging_handler = logging.FileHandler(log_file_name)
            self.logger.addHandler(self._seq_logging_handler)


    def _preload(self):
        """ loads image sequence from supplied file and resets the cache
            if self.preload_images, all images from the seq file are loaded into memory
        """
        self._state = 'loading'
        self.play_tick() #update display since we're blocking from now on

        #some fiddling with supplied matlab char-arrays
        if hasattr(self, 'param_image_seq_file'):  #pylint: disable=no-member
            seq_file = vco_utils.parse_matlab_char_array(self.param_image_seq_file)#pylint: disable=no-member
            self.current_seq_file = os.path.abspath(os.path.expanduser(seq_file))

        if not os.path.isfile(self.current_seq_file):
            self.logger.error("couldn't find sequence file %s, quitting", self.current_seq_file)
            time.sleep(1) #we sleep a bit to make sure the marker gets caught
            self.send_marker(markers.trial_end)
            time.sleep(1)
            sys.exit(2)


        self._image_cache = {}
        self.logger.debug("loading sequence file %s...", self.current_seq_file)
        self._image_seq = vco_utils.load_seq_file(self.current_seq_file)
        if not self._image_seq:
            #be expect at least one image, so return error
            self.logger.error("no images found in sequence file %s, quitting", self.current_seq_file)
            time.sleep(1) #we sleep a bit to make sure the marker gets caught
            self.send_marker(markers.trial_end)
            time.sleep(1)
            sys.exit(3)

        if self.preload_images:
            for seq_element in self._image_seq:
                self._get_image(seq_element[0])
            self.logger.debug("finished preloading of %d images", len(self._image_seq))

        self._current_image_no = 0
        #make sure at least the next image is preloaded
        self._get_image((self._image_seq[0])[0])

        self._state = 'standby'
#        self._last_clock_value = 0.0
        self.play_tick()
        #unfortunately, we cannot send the marker since pyff doesn't initialize
        # the socket until ._on_play() is called
        #self.send_marker(marker.preload_completed)


    def on_stop(self):
        """ Handler after receiving stop signal"""
        PygameFeedback.on_stop(self)
        self._state = 'standby'

    def on_quit(self):
        """ Handler after receiving quit signal"""
        self.send_marker(markers.feedback_quit)
        PygameFeedback.on_quit(self)

    def _get_image(self, file_name):
        """returns image for file name
            the image is loaded and cached if it it hasn't been cached yet
        """
        # self.logger.debug("retrieving image %s", file_name)
        if file_name not in self._image_cache:
            #self.logger.debug("loading image %s into memory", file_name)
            if not os.path.isfile(file_name):
                self.logger.error("couldn't find image %s from sequence file %s, quitting",
                                  file_name, self.current_seq_file)
                time.sleep(1) #we sleep a bit to make sure the marker gets caught
                self.send_marker(markers.trial_end)
                time.sleep(1)
                sys.exit(3)
            self._image_cache[file_name] = pygame.image.load(file_name)
        return self._image_cache[file_name]

    def _display_message(self, message):
        """prints the message on a black screen"""
        #recreate font each time, but caching it once crashes pygame on play-stop-play cycles
        monofont = pygame.font.SysFont("monospace", int(48*self.screenSize[0]/1920.0))
        label = monofont.render(message, 1, (200, 200, 200))
        self.screen.fill(self.backgroundColor)
        self.screen.blit(label, (int(self.screenSize[0]/2) - 100, int(self.screenSize[1]/2)))
        pygame.display.flip()


    def pause_tick(self):
        """ frame update when paused"""
        self._check_input() #listen for unpause

    def play_tick(self):
        """exec actual event loop based on state"""
        self._check_input()
        if self._state == "standby":
            self._display_message("Standby")
        elif self._state == "loading":
            self._display_message("Loading...")
        elif self._state == "playback":
            # first, send markers for current image
            # second, draw (including opto-marker)
            # third, advance state
            assert self._current_image_no < len(self._image_seq)
            current_element = self._image_seq[self._current_image_no]
            current_image_name = current_element[0]
            current_markers = current_element[1]

            if self._current_image_no == 0:
                self.logger.info('starting playback of %s', self.current_seq_file)
                self.send_marker(markers.trial_start)
            for marker in current_markers:
                self.send_marker(marker)
            if self._current_image_no % 50 == 0:
                self.send_marker(markers.sync_50_frames)
#                elapsed = time.clock() - self._last_clock_value
#                self._last_clock_value = time.clock()
#                self.logger.info("%f s for last 50 frame: FPS %f, should be %f" %
#                                 (elapsed, (50.0 / elapsed), self.FPS))
#                self.logger.info("pygame tells %f FPS" % self.clock.get_fps())

            #draw and display
            self._draw_image(current_image_name)
            self._draw_optomarker()
            pygame.display.flip()

            next_seq_no = self._current_image_no + 1
            if next_seq_no < len(self._image_seq):
                #force preload of next image (if not already done)
                self._get_image((self._image_seq[next_seq_no])[0])
                self._current_image_no = next_seq_no
            else:
                self.send_marker(markers.trial_end)
                self.logger.info('finished playback, going to standby')
                self._state = 'standby'


        else:
            self.logger.error("unknown state, exiting")
            self.send_marker(markers.trial_end)
            time.sleep(1)
            sys.exit(1)
            time.sleep(1)


    def _draw_image(self, image_name):
        """ draws the supplied image [file name] centered on the screen """
        image = self._get_image(image_name)
        cur_rect = image.get_rect()
        #center on screen
        cur_rect.topleft = (int((self.screen.get_width() - cur_rect.width) / 2.0),
                            int((self.screen.get_height() - cur_rect.height) / 2.0))
        self.screen.fill(self.backgroundColor)
        self.screen.blit(image, cur_rect)



    def _draw_optomarker(self):
        """ draw optomarker onto screen
           make sure this method is called after send_marker with the same _current_image_no
        """
        if (self.use_optomarker and
                self._current_image_no - self._last_marker_seq_no < self.optomarker_frame_length):
            pygame.draw.rect(self.screen, (255, 255, 255),
                             (0.49*self.screen.get_width(),
                              0.02*self.screen.get_height(), 20, 20))

    def _check_input(self):
        """ check for pause and enter events """
        if self.keypressed:
            if self._state == "playback" and self.lastkey in (pygame.K_RETURN, pygame.K_KP_ENTER): #pylint: disable=no-member
                self.send_marker(markers.return_pressed)
            if self.lastkey == pygame.K_SPACE: #pylint: disable=no-member
                self._paused = not self._paused #from MainloopFeedback pylint: disable=attribute-defined-outside-init
                self.send_marker(markers.playback_paused_toggled)
            self.keypressed = False #mark as handled pylint: disable=attribute-defined-outside-init

    def send_marker(self, data):
        """send marker both to parallel and to UDP"""
        self._last_marker_seq_no = self._current_image_no
        self.send_parallel(data)
        try:
            self.send_udp(str(data))
        except AttributeError: #if we call the feedback directly and the port is not set
            self.logger.error("could not send UDP marker %s", data)


def _run_example():
    """run feedback for test purposes"""
    logging.getLogger().addHandler(logging.StreamHandler())
    logging.getLogger().setLevel(logging.INFO)
    feedback = ImageSeqViewer()
    feedback.on_init()
    seq_file = '/mnt/blbt-fs1/backups/cake-hk1032/data/kitti/seqs/seq03_kelterstr.txt'
    feedback.param_image_seq_file = [ord(c) for c in seq_file]  #pylint: disable=attribute-defined-outside-init
    feedback.udp_markers_host = '127.0.0.1' #pylint: disable=attribute-defined-outside-init
    feedback.udp_markers_port = 12344 #pylint: disable=attribute-defined-outside-init
    feedback.pre_mainloop()
    feedback._state = 'playback' #pylint: disable=protected-access
    feedback._on_play() #pylint: disable=protected-access

if __name__ == "__main__":
    _run_example()
