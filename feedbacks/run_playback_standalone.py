#!/usr/bin/env python

import argparse
import logging
import os
import sys
import vco_utils

def _run_standalone(seq_file_fps_list_str, feedback_options=[]):
    """run feedback for test purposes"""

    #import here since we need to have pyff on the path first
    from image_sequence_playback import ImageSeqFeedback, BlockPreloadState
    
    logging.getLogger().addHandler(logging.StreamHandler())
    logging.getLogger().setLevel(logging.INFO)
    feedback = ImageSeqFeedback()
    feedback.on_init()
    feedback.udp_markers_host = '127.0.0.1'  #pylint: disable=attribute-defined-outside-init
    feedback.udp_markers_port = 12344 #pylint: disable=attribute-defined-outside-init
    feedback._handle_config_param('display_debug_information', True) #pylint: disable=protected-access
    #convert to char array as received by Matlab
    param_block_seq_file_fps_list = [ord(c) for c in seq_file_fps_list_str]  #pylint: disable=attribute-defined-outside-init
    feedback_options.append(
        ('next_block_info', param_block_seq_file_fps_list))
    for param_key, param_value in feedback_options:
        feedback._handle_config_param(param_key, param_value) #pylint: disable=protected-access
    print "starting with config %s" % feedback.config
    parsed_block_info = feedback.config['next_block_info']
    #instead of command, we force the state directly
    feedback._cur_state = BlockPreloadState(feedback, parsed_block_info, auto_play=True)#pylint: disable=attribute-defined-outside-init
    feedback.on_play()

def _handle_kv_string(value):
    split_str = value.split('=')
    if len(split_str) == 2:
        return (split_str[0], split_str[1])
    else:
        raise argparse.ArgumentTypeError('Must be specified as k=v')
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Feedback for image sequence playback')
    parser.add_argument('seq_files', nargs='+', help='sequence files to be played')
    parser.add_argument('-f', '--fps', default=10, help='FPS of playback')
    parser.add_argument('-pd', '--pyff_dir', default=vco_utils.get_pyff_path(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
                        help='path to pyff repo')
    parser.add_argument('-O', '--feedback_options', nargs='*', type=_handle_kv_string,
                        default=[], help='additional parameters for feedback')
    args = parser.parse_args()
    print args.feedback_options
    if not any(['pyff' in elem for elem in sys.path]):
        sys.path.append(os.path.join(os.path.expanduser(args.pyff_dir), "src"))
        print "added pyff directory %s to python path, now %s" % (args.pyff_dir, sys.path)

    cur_seq_fps_list = [(seq, args.fps) for seq in args.seq_files]
    _run_standalone(repr(cur_seq_fps_list), args.feedback_options)
