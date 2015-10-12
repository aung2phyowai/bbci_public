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
import seq_file_utils
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
        config/markers.ini (stimuli section only).

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
        self._unshown_marker = False
        self._start_date_string = datetime.datetime.now().isoformat().replace(":", "-")
        #explicit logger for sequences
        self._block_logging_handler = None

        self._seq_info_list = []
        self._current_seq_index = -1

        self._image_cache = {}
        self._current_image_seq = []
        self._last_interaction_image_no = -10

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
        self.logging_dir = tempfile.gettempdir()
        self.logging_prefix = 'image_seq_view'
        self.inter_sequence_delay = 5 #in seconds
        self.interaction_overlay_frame_count = 1


    def on_control_event(self, data):
        try:
            curFrame = self._current_image_no
        except:
            curFrame = -1
        self.logger.info("%d got control event %s\n with type %s",curFrame, data, type(data))
        #pass

    def pre_mainloop(self):
        """executed once after receiving play command"""
        self.screenSize = [int(self.screen_width), int(self.screen_height)] #pylint: disable=attribute-defined-outside-init
        self.screenPos = [self.screen_position_x, self.screen_position_y] #pylint: disable=attribute-defined-outside-init

        PygameFeedback.pre_mainloop(self)

        self._apply_settings()

        self._current_seq_index = 0
        self._init_current_sequence()

        #save state before playback
        pickle_file_name = os.path.join(self.logging_dir,
                                        self.logging_prefix + "_" + self._start_date_string + ".p")
        vco_utils.dump_settings(self, pickle_file_name)

        self._state = 'playback'



    def _setup_block_logger(self):
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

        # start logging per block
        if logging_setup_changed or self._block_logging_handler is None:
            log_file_name = os.path.join(self.logging_dir,
                                         self.logging_prefix + "_" + self._start_date_string + ".log")
            if self._block_logging_handler is not None:
                self.logger.removeHandler(self._block_logging_handler)
            self.logger.debug("writing sequence log to %s", log_file_name)
            self._block_logging_handler = logging.FileHandler(log_file_name)
            self.logger.addHandler(self._block_logging_handler)

    def _apply_settings(self):
        """ apply all settings (sent by matlab) and reset state (including cache)
            if preloading is activated, all images of all sequences [of the block] are loaded into memory
        """
        self._state = 'loading'
        self.play_tick() #update display since we're blocking from now on

        self._image_cache = {}
        self._setup_block_logger()

        #load new sequence information if available
        if hasattr(self, 'param_block_seq_file_fps_list'):  #pylint: disable=no-member
            seq_fps_string = vco_utils.parse_matlab_char_array(self.param_block_seq_file_fps_list)#pylint: disable=no-member
            #dangerous, but we expect to be i	n a trustworthy environment...
            seq_fps_list = eval(seq_fps_string.replace('\\', '\\\\')) #pylint: disable=eval-used

            self._seq_info_list = []
            self._current_seq_index = -1

            #load and validate all sequences of the block
            for seq_fps_tuple in seq_fps_list:
                #expand seq file name to full path
                seq_file = os.path.abspath(os.path.expanduser(os.path.normpath(seq_fps_tuple[0])))
                seq_fps = seq_fps_tuple[1]
                if not os.path.isfile(seq_file):
                    self.logger.error("couldn't find sequence file %s, quitting", seq_file)
                    time.sleep(1) #we sleep a bit to make sure the marker gets caught
                    self.send_marker(markers.technical['trial_end'])
                    time.sleep(1)
                    sys.exit(2)

                self.logger.debug("loading sequence file %s...", seq_file)
                image_seq = seq_file_utils.load_seq_file(seq_file)
                if not image_seq:
                    #we expect at least one image, so return error
                    self.logger.error("no images found in sequence file %s, quitting", seq_file)
                    time.sleep(1) #we sleep a bit to make sure the marker gets caught
                    self.send_marker(markers.technical['trial_end'])
                    time.sleep(1)
                    sys.exit(3)
                if self.preload_images:
                    for seq_element in image_seq:
                        self._get_image(seq_element.file_name)
                    self.logger.debug("finished preloading of %d images", len(image_seq))
                self._seq_info_list.append((seq_file, seq_fps, image_seq))


        if not self._seq_info_list:
            #we expect at least one sequence file, so return error
            self.logger.error("no sequence file found in parameter param_block_seq_file_fps_list, quitting")
            time.sleep(1) #we sleep a bit to make sure the marker gets caught
            self.send_marker(markers.technical['trial_end'])
            time.sleep(1)
            sys.exit(1)

        #unfortunately, we cannot send the marker since pyff doesn't initialize
        # the socket until ._on_play() is called
        #self.send_marker(marker.preload_completed)


        self._state = 'standby'
        self.play_tick()



    def _init_current_sequence(self):
        """initialize playback state for the sequence with index self._current_seq_index"""
        current_seq_info = self._seq_info_list[self._current_seq_index]
        self._current_image_seq = current_seq_info[2]
        self._current_image_no = 0
        self._last_interaction_image_no = -1 - self.interaction_overlay_frame_count
        self.FPS = current_seq_info[1]
        #make sure at least the next image is preloaded
        self._get_image((self._current_image_seq[0]).file_name)
        self.logger.debug("initialized sequence file %s", current_seq_info[0])


    def on_stop(self):
        """ Handler after receiving stop signal"""
        PygameFeedback.on_stop(self)
        self._state = 'standby'

    def on_quit(self):
        """ Handler after receiving quit signal"""
        self.send_marker(markers.technical['feedback_quit'])
        PygameFeedback.on_quit(self)

    def _get_image(self, file_name):
        """returns image for file name
            the image is loaded and cached if it it hasn't been cached yet
        """
        # self.logger.debug("retrieving image %s", file_name)
        if file_name not in self._image_cache:
            #self.logger.debug("loading image %s into memory", file_name)
            try:
                self._image_cache[file_name] = pygame.image.load(file_name)
            except BaseException as e:
                self.logger.error(e)
                #maybe we're on windows and encountered a symbolic link
                #this means we can read the target as a text
                self.logger.error("couldn't directly load %s", file_name)
                try:
                    with open(file_name, "r") as txt_file:
                        rel_target = txt_file.read()
                        abs_target = os.path.normpath(os.path.join(os.path.dirname(file_name), rel_target))
                        self.logger.debug("found target: %s", abs_target)
                        #prevent infinite loop
                        if os.path.exists(abs_target) and abs_target != file_name:
                            return self._get_image(abs_target)
                        else:
                            raise ValueError("non-existing target or infinite loop trying to load %s" % abs_target)
                except BaseException as f:
                    self.logger.error(f)
                    self.logger.error("couldn't open image %s, quitting",
                                      file_name)
                    #time.sleep(1) #we sleep a bit to make sure the marker gets caught
                    #self.send_marker(markers.technical['trial_end'])
                    #time.sleep(1)
                    #sys.exit(3)
                    return None
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
        elif self._state == "waiting":
            self.screen.fill(self.backgroundColor)
            pygame.display.flip()
            self._current_image_no += 1
            waitingFrameCount = self.inter_sequence_delay * self.FPS
            if self._current_image_no >= waitingFrameCount:                
                self._init_current_sequence()
                self._state = "playback"
        elif self._state == "playback":
            # first, send markers for current image
            # second, draw (including opto-marker)
            # third, advance state
            assert self._current_image_no < len(self._current_image_seq)
            current_element = self._current_image_seq[self._current_image_no]
            current_image_name = current_element.file_name
            current_markers = [marker[0] for marker in current_element.marker_tuples]

            if self._current_image_no == 0:
                if self._current_seq_index == 0:
                    #complete start, not only new sequence
                    #yet this causes duplicate markers on same frame
                    #self.send_marker(markers.technical['trial_start'])
                    pass
                self.logger.info('starting playback of sequence %d with %dFPS (file: %s)',
                                 self._current_seq_index, self.FPS,
                                 (self._seq_info_list[self._current_seq_index])[0])
                self.send_marker(markers.technical['seq_start'])
            for marker in current_markers:
                self.send_marker(marker)
            if self._current_image_no % 50 == 0:
                self.send_marker(markers.technical['sync_50_frames'])

            #advance state, current image is still in local variable for later drawing
            # we do this before display to make sure that optomarkers are drawn
            next_seq_no = self._current_image_no + 1
            if next_seq_no < len(self._current_image_seq):
                #force preload of next image (if not already done)
                self._get_image((self._current_image_seq[next_seq_no]).file_name)
                self._current_image_no = next_seq_no
            else: # sequence is over
                self.send_marker(markers.technical['seq_end'])
                if self._current_seq_index + 1 < len(self._seq_info_list):
                    # the block has another sequence
                    self._current_seq_index += 1
                    self._current_image_no = 0 #use this for counting of break duration
                    self._state = 'waiting'
                else:
                    self.send_marker(markers.technical['trial_end'])
                    self.logger.info('finished playback, going to standby')
                    self._state = 'standby'

            #draw and display
            if self._current_image_no - 1 - self._last_interaction_image_no  < self.interaction_overlay_frame_count:
                self._draw_interaction_overlay()
            else:
                self._draw_image(current_image_name)
            self._draw_optomarker()
            pygame.display.flip()
            
        else:
            self.logger.error("unknown state, exiting")
            self.send_marker(markers.technical['trial_end'])
            time.sleep(1)
            sys.exit(1)
            time.sleep(1)


    def _draw_image(self, image_name):
        """ draws the supplied image [file name] centered on the screen """
        image = self._get_image(image_name)
        self._cur_image_rect = image.get_rect() #save, so we have the dimensions of the last drawn image
        #center on screen
        self._cur_image_rect.topleft = (int((self.screen.get_width() - self._cur_image_rect.width) / 2.0),
                            int((self.screen.get_height() - self._cur_image_rect.height) / 2.0))
        self.screen.fill(self.backgroundColor)
        self.screen.blit(image, self._cur_image_rect)


    def _draw_interaction_overlay(self):
        self.screen.fill((255, 255, 255), rect=self._cur_image_rect)

    def _draw_optomarker(self):
        """ draw optomarker onto screen
           make sure this method is called after send_marker
        """
        if self.use_optomarker:
            marker_rect_coords = (0.49*self.screen.get_width(),
                                  0.02*self.screen.get_height(), 20, 20)
            if self._unshown_marker:
                pygame.draw.rect(self.screen, (255, 255, 255),
                                 marker_rect_coords)
                self._unshown_marker = False
            else: #black out screen
                 pygame.draw.rect(self.screen, (0, 0, 0),
                                 marker_rect_coords)

    def _check_input(self):
        """ check for pause and enter events """
        if self.keypressed:
            if self._state == "playback" and self.lastkey in (pygame.K_RETURN, pygame.K_KP_ENTER): #pylint: disable=no-member
                self.send_marker(markers.interactions['button_pressed'])
                self._last_interaction_image_no = self._current_image_no
            if self.lastkey == pygame.K_SPACE: #pylint: disable=no-member
                self._paused = not self._paused #from MainloopFeedback pylint: disable=attribute-defined-outside-init
                self.send_marker(markers.interactions['playback_paused_toggled'])
            self.keypressed = False #mark as handled pylint: disable=attribute-defined-outside-init

    def send_marker(self, data):
        """send marker both to parallel and to UDP"""
        self._unshown_marker = True
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
    seq_fps_list = '[("/mnt/blbt-fs1/backups/cake-hk1032/data/kitti/seqs/seq03_kelterstr.txt", 10)]'
    feedback.param_block_seq_file_fps_list = [ord(c) for c in seq_fps_list]  #pylint: disable=attribute-defined-outside-init
    feedback.udp_markers_host = '127.0.0.1' #pylint: disable=attribute-defined-outside-init
    feedback.udp_markers_port = 12344 #pylint: disable=attribute-defined-outside-init
    feedback.on_play() #pylint: disable=protected-access

if __name__ == "__main__":
    _run_example()
