#!/usr/bin/env python

# ImageSeqViewer.py -

"""Displays a ``video'' from a sequence of images."""


import os
import sys
import logging
import time

import pygame

from pygame import Rect
from FeedbackBase.PygameFeedback import PygameFeedback


from Marker import Marker

class ImageSeqViewer(PygameFeedback):
    """Feedback for playback of image sequences
    
       Images are read from ``sequence files'' that are of the form
         ${relativeFileName}\t${optionalMarker1}\t${optionalMarkerN}
        The file format can easily be created with, e.g., 
         `ls -1 ../original/2011_10_03_drive_0047_sync/image_02/data/*`
       Relative paths are resolved relative to the sequence file's
        location (semantics of os.path.join).
       Markers can either be integers or names of attributes in the
        Marker class.
       
       If preload_images is true (as is the default), all images are
        loaded into memory at once.
    """

    def init(self):
        PygameFeedback.init(self)

        #init public state (typically partially overriden by Matlab)
        self.caption = "Image Sequence Viewer"
        self.image_width = 1242
        self.image_height = 375
        # use separate variables to avoid type conversions
        #  when interacting with Matlab
        self.screen_width = self.image_width + 100
        self.screen_height = self.image_height + 200
        self.screen_position_x = 400
        self.screen_position_y = 400
        self.fullscreen = False #fullscreen seems to be broken
        self.preload_images = True
        self.use_optomarker = True
        #for how many frames should the marker be displayed
        self.optomarker_frame_length = 2

        #init private state
        self._state = 'standby'
        self._last_marker_seq_no = -1 - self.optomarker_frame_length

    def on_interaction_event(self, data):
        # self.logger.info("got event: %s\n with type %s" % (data, type(data)))

        # update screenSize if width or height change
        if ('screen_width' in data or
            'screen_height' in data):
            self.screenSize = [int(self.screen_width), int(self.screen_height)]
                
        # workaround - actually a command, but those don't cause an interaction event
        if 'trigger_preload' in data:
            self.logger.info("triggering preload")
            self._preload()
        PygameFeedback.on_interaction_event(self, data)

    def on_control_event(self, data):
        self.logger.info("got control event %s\n with type %s" % (data, type(data)))

    def pre_mainloop(self):
        """executed once after receiving play command"""
        self.screenSize = [int(self.screen_width), int(self.screen_height)]
        self.screenPos = [self.screen_position_x, self.screen_position_y]
        
        PygameFeedback.pre_mainloop(self)
        
        #trigger preload (if enabled)
        self._preload()
        self._state = 'playback'
        
    def _preload(self):
        """ loads image sequence from supplied file and resets the cache
            if self.preload_images, all images from the seq file are loaded into memory 
        """
        self._state = 'loading'
        self.play_tick() #update display since we're blocking from now on

        #some fiddling with supplied matlab char-arrays
        if hasattr(self, 'param_image_seq_file') and isinstance(self.param_image_seq_file[0],float):
            prefix = [chr(int(i)) for i in self.param_image_seq_file]
            self.image_seq_file = ''.join(prefix)

        #normalize file path
        self.image_seq_file = os.path.abspath(os.path.expanduser(self.image_seq_file))
        self._image_cache = {}
        self._loadSeqFile()
        if self.preload_images:
            for seq_element in self._image_seq:
                self._get_image(seq_element[0])
            
        self._current_seq_no = -1 #gets directly incremented a few lines below
        self._next_file_exists = True
        self._readNextImage()
        if self._next_file_exists: #if we could read the first image, use it as current
            self._current_image = self._next_image
            self._current_markers = self._next_markers
            self._current_seq_no = self._current_seq_no + 1
            self._readNextImage()
        else:
            self.logger.error("couldn't find first image from sequence file %s, quitting" % self.image_seq_file)
            sys.exit(10)


        self._current_seq_no = 0
        self._state = 'standby'
        self._last_clock_value = 0.0
        self.play_tick()
        #unfortunately, we cannot send the marker since pyff doesn't initialize
        # the socket until ._on_play() is called
        #self.send_marker(Marker.preload_completed)


     

    # load a file containing an image sequence
    #  expected format
    #   ${relativeFileName}\t${optionalMarker1}\t${optionalMarkerN}
    # the file format can easily be created with e.g., 
    # ls -1 ../original/2011_10_03_drive_0047_sync/image_02/data/*
    def _loadSeqFile(self):
        """
        load a file containing an image sequence
         expected format
          ${relativeFileName}\t${optionalMarker1}\t${optionalMarkerN}
         the file format can easily be created with e.g., 
          ls -1 ../original/2011_10_03_drive_0047_sync/image_02/data/*
         lines starting with # are ignored
        """
        
        #process markers in the sequence file
        def processMarker(marker_str):
            try:
                return int(marker_str)
            except ValueError:
                if hasattr(Marker, marker_str):
                    return getattr(Marker, marker_str)
                else:
                    return Marker.generic_event
        #process each line in the seq file
        def parseLine(line):
             fields = line.rstrip('\n').split('\t')
             return (fields[0], [processMarker(marker_string) for marker_string in fields[1:]])
        # do the actual work
        self._image_seq = [parseLine(l) for l in open(self.image_seq_file) if not l.lstrip().startswith('#') ]

    #read next image and markers from image_seq into dedicated variable
    def _readNextImage(self):
        self._next_file_exists = False
        if self._current_seq_no + 1 < len(self._image_seq):
            next_seq_element = self._image_seq[self._current_seq_no + 1]
            #might block if the image has not been preloaded yet
            self._next_image = self._get_image(next_seq_element[0])
            self._next_markers = next_seq_element[1]
            self._next_file_exists = True

    def on_play(self):
        self._state = 'playback'
        #block for 1 second to ensure bbci online is started
        #(in case we trigger it from matlab)
        time.sleep(1)
        PygameFeedback.on_play(self)
          
    def on_stop(self):
        PygameFeedback.on_stop(self)
        self._state = 'standby'

    def on_quit(self):
        self.send_marker(Marker.feedback_quit)
        PygameFeedback.on_quit(self)

    def on_control_event(self, data):
        #do nothing, but prevent logging
        pass

    def _get_image(self, key):
       # self.logger.debug("retrieving image %s" % key)
        if key not in self._image_cache:
            next_file_name = os.path.join(os.path.dirname(self.image_seq_file), os.path.normpath(key))
            self._image_cache[key] = pygame.image.load(next_file_name)
        return self._image_cache[key]

    def _print_message(self, message):
         """prints the message on a black screen"""
         #recreate font each time, but caching it once crashes pygame on play-stop-play cycles
         monofont = pygame.font.SysFont("monospace", int(48*self.screenSize[0]/1920.0))
         label = monofont.render(message, 1, (200,200,200))
         self.screen.fill(self.backgroundColor)
         self.screen.blit(label, (int(self.screenSize[0]/2) - 100, int(self.screenSize[1]/2)))
         pygame.display.flip()


    def tick(self):
        # make sure we check input also in paused state
        self._checkInput()
        PygameFeedback.tick(self)
        
        
    def play_tick(self):
        """exec actual event loop based on state"""
        if self._state == "standby":
           self._print_message("Standby")
        elif self._state == "loading":
            self._print_message("Loading...")
        elif self._state == "playback":
            # first, send markers for current image
            # second, draw (including opto-marker)
            # third, advance state

            if self._current_seq_no == 0:
                self.send_marker(Marker.trial_start)
            for marker in self._current_markers:
                self.send_marker(marker)
            if self._current_seq_no % 50 == 0:
                self.send_marker(Marker.sync_50_frames)
                elapsed = time.clock() - self._last_clock_value
                self._last_clock_value = time.clock()
#                self.logger.info("%f s for last 50 frame: FPS %f, should be %f" % (elapsed, (50.0 / elapsed), self.FPS))
#                self.logger.info("pygame tells %f FPS" % self.clock.get_fps())

            self._drawCurrentImage()
            
            if self._next_file_exists:
                self._current_image = self._next_image
                self._current_markers = self._next_markers
                self._current_seq_no = self._current_seq_no + 1
                self._readNextImage()
                #to improve speed of later blit (c.f., http://www.pygame.org/docs/ref/surface.html#pygame.Surface.convert)
                self._current_image.convert(self.screen)
            else:
                self.send_marker(Marker.trial_end)                
                self.logger.info('new state: playback -> standby')
                self._state = 'standby'
            
                
        else:
            self.logger.error("unknown state")
            sys.exit(1)


    def _drawCurrentImage(self):
         curRect = self._current_image.get_rect()
         #center on screen
         curRect.topleft = (int((self.screen.get_width() - self.image_width) / 2.0),
                            int((self.screen.get_height() - self.image_height) / 2.0))
         self.screen.fill(self.backgroundColor)
         self.screen.blit(self._current_image, curRect)
         if (self.use_optomarker and
             self._current_seq_no - self._last_marker_seq_no < self.optomarker_frame_length):
             #draw marker
             pygame.draw.rect(self.screen, (255,255,255), (0.49*self.screen.get_width(), 0.02*self.screen.get_height(), 20,20))
         pygame.display.flip()

    def _checkInput(self):
        if self.keypressed:
            if self._state == "playback" and self.lastkey in (pygame.K_RETURN, pygame.K_KP_ENTER):
                self.send_marker(Marker.return_pressed)
            if self.lastkey == pygame.K_SPACE:
                self._paused = not self._paused
                self.send_marker(Marker.playback_paused_toggled)
            self.keypressed = False #mark as handled
    
    def send_marker(self,data):
        """send marker both to parallel and to UDP"""
        self._last_marker_seq_no = self._current_seq_no
        self.send_parallel(data)
        try:
            self.send_udp(str(data))
        except AttributeError: #if we call the feedback directly and the port is not set
            self.logger.error("could not send UDP marker %s" % data)

if __name__ == "__main__":
    """ debugging calls for direct start"""
    logging.getLogger().addHandler(logging.StreamHandler())
    logging.getLogger().setLevel(logging.INFO)
    fb = ImageSeqViewer()
    fb.on_init()
    fb.image_seq_file = '/mnt/blbt-fs1/backups/cake-hk1032/data/kitti/seqs/seq03_kelterstr.txt'
    fb.udp_markers_host = '127.0.0.1'
    fb.udp_markers_port = 12344
    fb.pre_mainloop()
    fb.state = 'playback'
    fb._on_play()
