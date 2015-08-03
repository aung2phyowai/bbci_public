#!/usr/bin/env python

# ImageSeqViewer.py -

"""Displays a ``video'' from a sequence of images."""


import os
import sys
import logging

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
        self.FPS = 10
        self.state = 'standby'


        self.original_image_path = '/home/henkolk/local_data/kitti/rural'



    def pre_mainloop(self):
        PygameFeedback.pre_mainloop(self)

        if hasattr(self, 'param_image_path') and isinstance(self.param_image_path[0],float):
            prefix = [chr(int(i)) for i in self.param_image_path]
            self.image_path = ''.join(prefix)
        else:
            self.image_path = self.original_image_path
        
        self.current_seq_no = -1 #gets directly incremented a few lines below
        self.next_file_exists = True
        self.readNextImage()
        if self.next_file_exists: #if we could read the first image, use it as current
            self.current_image = self.next_image
            self.current_seq_no = self.current_seq_no + 1
            self.readNextImage()
        else:
            print >> sys.stderr, "couldn't find first file in path %s, quitting" % self.image_path
            sys.exit(10)
        
        self.state = 'playback'


#    def init_graphics(self):
        # load graphics

        # init background
#        self.background = pygame.Surface((self.screen_pos[2], self.screen_pos[3]))
#        self.background = self.background.convert()
#        self.backgroundRect = self.background.get_rect(center=self.screen.get_rect().center)
#        self.background.fill(self.backgroundColor)#
#
#        self.screen.blit(self.background, self.backgroundRect)
#        pygame.display.update()#


#        if self.fullscreen:
#            self.screen = pygame.display.set_mode((self.screen_pos[2], self.screen_pos[3]), pygame.FULLSCREEN)
#        else:
#            self.screen = pygame.display.set_mode((self.screen_pos[2], self.screen_pos[3]), pygame.RESIZABLE)##

#        self.screen = pygame.display.get_surface()
#        self.size = min(self.screen.get_height(), self.screen.get_width())
        

    def readNextImage(self):
        nextFileName = os.path.join(self.image_path, "%010d.png" % (self.current_seq_no + 1))
        if os.access(nextFileName, os.R_OK):
            self.next_file_exists = True
            self.next_image = pygame.image.load(nextFileName)
        else:
            self.next_file_exists = False

    def on_play(self):
        self.state = 'playback'
        PygameFeedback.on_play(self)
          
    def on_stop(self):
        PygameFeedback.on_stop(self)
        self.state = 'standby'

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
        
            if (self.current_seq_no == 0):
                self.send_marker(Marker.trial_start)
#            if self.current_seq_no % 50 == 0:
#                self.FPS = 1.5*self.FPS
#                self.logger.info("advanced to %d FPS" % self.FPS)

            pos = (0, 0)
            curRect = self.current_image.get_rect()
            curRect.topleft = pos
            self.screen.fill(self.backgroundColor)
            self.screen.blit(self.current_image, curRect)
            pygame.display.flip()

            if self.next_file_exists:
                self.current_image = self.next_image
                self.current_seq_no = self.current_seq_no + 1
                self.readNextImage()
            else:
#                self.send_marker(Marker.trial_end)
                self.send_marker(Marker.feedback_quit)
                self.logger.info('new state: playback -> standby')
                self.state = 'standby'
                
        else:
            print >> sys.stderr, "unknown state"
            sys.exit(1)

    
    def send_marker(self,data):
        self.send_parallel(data)
        try:
            self.send_udp(str(data))
        except AttributeError: #if we call the feedback directly and the port is not set
            print >> sys.stderr, "could not send UDP marker %s" % data

if __name__ == "__main__":
    logging.getLogger().addHandler(logging.StreamHandler())
    fb = ImageSeqViewer()
    fb.on_init()
    fb.pre_mainloop()
    fb.state = 'playback'
    fb.on_play()
