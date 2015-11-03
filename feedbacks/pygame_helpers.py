""" utility routines for pygame """

import logging
import os
import pygame

#Note: the first parameter surface usually corresponds to the screen created by pygame.display.set_mode(...)

def draw_image(surface, image):
    """ draws an image centered on the surface"""
    cur_image_rect = image.get_rect()
    #center on screen
    cur_image_rect.topleft = (int((surface.get_width() - cur_image_rect.width) / 2.0),
                              int((surface.get_height() - cur_image_rect.height) / 2.0))
    surface.blit(image, cur_image_rect)

def draw_interaction_overlay(surface, config):
    """ draws an overlay at the center of screen (outside of optomarker region) """
    top_margin = 3 * config['optomarker_width']
    # overlay_rect = (0, top_margin,
    #                 surface.get_width(), surface.get_height() - top_margin)
    # surface.fill(config['overlay_color'], rect=overlay_rect)
    overlay_surface = pygame.Surface((surface.get_width(), surface.get_height()), pygame.SRCALPHA, 32)
    overlay_surface.fill(config['overlay_color'])
    surface.blit(overlay_surface, (0, top_margin))


def draw_optomarker(surface, unshown_marker, config):
    """ draw optomarker onto screen
    make sure this method is called after send_marker
    """
    if config['optomarker_enabled']:
        size = config['optomarker_width']
        #use top margin identical to side length
        marker_rect_coords = (int(0.485*config['screen_width']), int(0.01*config['screen_width']),
                              size, size)
        #currently on audio lab: (931, 19, 30, 30)
        #line from famox:
        #pygame.draw.rect(self.screen, (255,255,255), (0.485*self.screen.get_width(), 0.01*self.screen.get_width(), 30, 30))
        if unshown_marker:
            pygame.draw.rect(surface, (255, 255, 255),
                             marker_rect_coords)
        else: #black out screen
            pygame.draw.rect(surface, config['background_color'],
                             marker_rect_coords)

def display_message(surface, message, pos=(0, 0), size=40, color=(200, 200, 200)):
    """prints the message on a black screen"""
    #recreate font each time, but caching it once crashes pygame on play-stop-play cycles
    monofont = pygame.font.SysFont("monospace", size)
    label = monofont.render(message, 1, color)
    surface.blit(label, pos)

def draw_center_cross(surface, color=(100, 100, 100)):
    """ This will draw a cross in the center of the screen """
    abs_height = surface.get_height()
    abs_width = surface.get_width()
    pygame.draw.rect(surface, color, (abs_width / 2 - 30, abs_height / 2 - 3, 60, 6))
    pygame.draw.rect(surface, color, (abs_width / 2 - 3, abs_height / 2 - 30, 6, 60))

def draw_abstract_stimulus(surface, color=(100, 100, 100), width=80):
    """draws a box centered on the screen"""
    center_x = surface.get_width() / 2
    center_y = surface.get_height() / 2
    pygame.draw.rect(surface, color, (center_x - width/2, center_y - width/2, width, width))
    
def load_image(filename, max_depth=10):
    """loads an image and returns the corresponding object
       if filename points to a text file containing another file path (as occurs when checking out symbolic links on Windows), this file path is loaded (recursively)"""
    logger = logging.getLogger("vco.technical")
    #we follow links, so create a loop here, see comments below
    visited_files = []
    file_to_load = filename
    cur_depth = 0
    continue_loop = True
    image = None
    while continue_loop:
        try:
            image = pygame.image.load(file_to_load)
            continue_loop = False
        except BaseException as error:
            logger.error("couldn't directly load %s, threw %s", filename, error)
            visited_files.append(file_to_load)
            cur_depth += 1
            if cur_depth >= max_depth:
                logger.error("exceeded max link depth of %d", max_depth)
                continue_loop = False
            else:
                #maybe we're on windows and encountered a symbolic link
                #this means we can read the target as a text
                try:
                    with open(file_to_load, "r") as txt_file:
                        rel_target = txt_file.read()
                        abs_target = os.path.normpath(os.path.join(os.path.dirname(file_to_load), rel_target))
                        logger.debug("found target %s", abs_target)
                        if abs_target in visited_files:
                            logger.error("found loop in file links")
                            continue_loop = False
                        if not os.path.exists(abs_target):
                            logger.error("target file %s not found", abs_target)
                            continue_loop = False
                        file_to_load = abs_target
                except BaseException as read_error:
                    logger.error("couldn't open file as text file, hence no link, error %s", read_error)
                    continue_loop = False
    return image
