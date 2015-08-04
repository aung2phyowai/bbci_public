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

    def init(self):
        PygameFeedback.init(self)
        self.caption = "Image Seq Viewer"

        self.screenPos = [400, 400]
        self.screenSize = [1242, 375]
#        self.FPS = 10
        self.state = 'standby'


    def pre_mainloop(self):
        PygameFeedback.pre_mainloop(self)

        if hasattr(self, 'param_image_seq_file') and isinstance(self.param_image_seq_file[0],float):
            prefix = [chr(int(i)) for i in self.param_image_seq_file]
            self.image_seq_file = ''.join(prefix)

        self.loadSeqFile()
            
        self.current_seq_no = -1 #gets directly incremented a few lines below
        self.next_file_exists = True
        self.readNextImage()
        if self.next_file_exists: #if we could read the first image, use it as current
            self.current_image = self.next_image
            self.current_markers = self.next_markers
            self.current_seq_no = self.current_seq_no + 1
            self.readNextImage()
        else:
            self.logger.error("couldn't find first image from sequence file %s, quitting" % self.image_seq_file)
            sys.exit(10)
        
        self.state = 'playback'
        self.last_clock_value = 0.0

    # load a file containing an image sequence
    #  expected format
    #   ${relativeFileName}\t${optionalMarker1}\t${optionalMarkerN}
    # the file format can easily be created with e.g., 
    # ls -1 ../original/2011_10_03_drive_0047_sync/image_02/data/*
    def loadSeqFile(self):
        def parseLine(line):
             fields = line.rstrip('\n').split('\t')
             return (fields[0], [int(marker_string) for marker_string in fields[1:]])
        self.image_seq = [parseLine(l) for l in open(self.image_seq_file) if not l.lstrip().startswith('#') ]

    def readNextImage(self):
#       nextFileName = os.path.join(self.image_path, "%010d.png" % (self.current_seq_no + 1))
        self.next_file_exists = False
        if self.current_seq_no + 1 < len(self.image_seq):
            nextSeqElement = self.image_seq[self.current_seq_no + 1]
            nextFileName = os.path.join(os.path.dirname(self.image_seq_file), nextSeqElement[0])
            if os.access(nextFileName, os.R_OK):
                # read image
                self.next_file_exists = True
                self.next_image = pygame.image.load(nextFileName)
                # prepare markers if available
                self.next_markers = nextSeqElement[1]

    def on_play(self):
        self.state = 'playback'
        #block for 1 second to ensure bbci online is started
        #(in case we trigger it from matlab)
        time.sleep(1)
        PygameFeedback.on_play(self)
          
    def on_stop(self):
        PygameFeedback.on_stop(self)
        self.state = 'standby'

    def on_quit(self):
        self.send_marker(Marker.feedback_quit)
        PygameFeedback.on_quit(self)

    def on_control_event(self, data):
        #do nothing, but prevent logging
        pass
        
    def play_tick(self):
        if self.state == "standby":
            myfont = pygame.font.SysFont("monospace", int(48*self.screenSize[0]/1920.0))
            label = myfont.render("Standby", 1, (200,200,200))
            self.screen.fill(self.backgroundColor)
            self.screen.blit(label, (int(self.screenSize[0]/2) - 100, int(self.screenSize[1]/2)))
            pygame.display.flip()

        elif self.state == "playback":
            pos = (0, 0)
            curRect = self.current_image.get_rect()
            curRect.topleft = pos
            self.screen.fill(self.backgroundColor)
            self.screen.blit(self.current_image, curRect)
            pygame.display.flip()

            if self.current_seq_no == 0:
                self.send_marker(Marker.trial_start)
            for marker in self.current_markers:
                self.send_marker(marker)
            if self.current_seq_no % 50 == 0:
                self.send_marker(Marker.sync_50_frames)
                elapsed = time.clock() - self.last_clock_value
                self.last_clock_value = time.clock()
                self.logger.info("%f s for last 50 frame: FPS %f, should be %f" % (elapsed, (50.0 / elapsed), self.FPS))
                self.logger.info("pygame tells %f FPS" % self.clock.get_fps())
           

            if self.next_file_exists:
                self.current_image = self.next_image
                self.current_markers = self.next_markers
                self.current_seq_no = self.current_seq_no + 1
                self.readNextImage()
            else:
                self.send_marker(Marker.trial_end)                
                self.logger.info('new state: playback -> standby')
                self.state = 'standby'
                
        else:
            self.logger.error("unknown state")
            sys.exit(1)

    
    def send_marker(self,data):
        self.send_parallel(data)
        try:
            self.send_udp(str(data))
        except AttributeError: #if we call the feedback directly and the port is not set
            self.logger.error("could not send UDP marker %s" % data)

if __name__ == "__main__":
    logging.getLogger().addHandler(logging.StreamHandler())
    logging.getLogger().setLevel(logging.INFO)
    fb = ImageSeqViewer()
    fb.on_init()
    fb.image_seq_file = '/mnt/blbt-fs1/backups/cake-hk1032/data/kitti/seqs/seq01_aldi.txt'
    fb.udp_markers_host = '127.0.0.1'
    fb.udp_markers_port = 12344
    fb.pre_mainloop()
    fb.state = 'playback'
    fb._on_play()
