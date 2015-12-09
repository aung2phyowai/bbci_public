#!/usr/bin/env python

import argparse
import csv
import logging
import os
import re
import sys

feedback_path = os.path.normpath(os.path.join(os.path.dirname(__file__), "../feedbacks"))
sys.path.append(feedback_path)
import markers
import seq_file_utils

wyrm_path = os.path.normpath(os.path.join(os.path.dirname(__file__), "../../wyrm"))
sys.path.append(wyrm_path)
import wyrm.io



def validate_block_markers(bv_vhdr_file, expected_block_markers):
    """checks if all expected markers (from the sequence files) appear in the recording
     additional markers are accepted"""
    #we could do dynamic programming for alignment, just check for errors now
    dat = wyrm.io.load_brain_vision_data(bv_vhdr_file)
    stim_marker_pattern = r"^S[ ]*(\d+)$"
    marker_matches = [re.match(stim_marker_pattern, tup[1]) for tup in dat.markers]
    rec_stim_markers = [int(m.group(1)) for m in marker_matches if m]
    next_expected = 0
    for rec_marker in rec_stim_markers:
        if (next_expected < len(expected_block_markers) and
            rec_marker == expected_block_markers[next_expected]):
            next_expected += 1
    return next_expected == len(expected_block_markers)


def load_block_structure_markers(bs_file, data_dir):
    """ loads all expected markers from the sequence files
        defined in the block structure given by bs_file"""
    markers_by_block = {}
    with open(bs_file) as fp:
        tsv_reader = csv.reader(fp, delimiter='\t')
        next(tsv_reader) #skip header
        for row in tsv_reader:
            block_no = int(row[0])
            if block_no not in markers_by_block:
                markers_by_block[block_no] = []
            seq_file_name = os.path.normpath(os.path.join(data_dir, row[1]))
            image_marker_list = seq_file_utils.load_seq_file(seq_file_name)
            markers_by_block[block_no].append(markers.technical['seq_start'])
            seq_markers = [min([marker.value for marker in frame.marker_tuples]) for frame in image_marker_list if frame.marker_tuples]
            markers_by_block[block_no].extend(seq_markers)
    return markers_by_block

def get_recorded_blocks(rec_dir, rec_type):
    """get all available recorded block in a rec dir"""
    prefix = '_'.join([os.path.basename(rec_dir), rec_type])
    re_pattern = prefix + "_block(\\d+)"
    recorded_blocks = {}
    for cur_file in os.listdir(rec_dir):
        match = re.match(re_pattern + "\\.vhdr", cur_file)
        if match:
            block_no = int(match.group(1))
            #get without ending
            recorded_blocks[block_no] = re.match(re_pattern, cur_file).group(0)
    return recorded_blocks


def validate_experiment_recording(rec_dir, rec_type, data_dir):
    """validates a recording; 
       this includes
        - existence of all expected markers"""
    blockstructure_file = os.path.abspath(os.path.join(rec_dir, 'block_structure.tsv'))
    expected_markers_by_block = load_block_structure_markers(blockstructure_file, data_dir)
    blocks = get_recorded_blocks(rec_dir, rec_type)
    for block_no, block_prefix in blocks.items():
        vhdr_file = os.path.join(rec_dir, block_prefix + '.vhdr')
        if not validate_block_markers(vhdr_file, expected_markers_by_block[block_no]):
            logging.error("did not find all markers in block %d", block_no)

if __name__ == "__main__":
    logging.basicConfig(level=logging.WARNING)
    wyrm.io.logger.setLevel(logging.WARNING)
    parser = argparse.ArgumentParser(description='validates BV recording')
    parser.add_argument('rec_dir', help="directory with recording (bbciRaw)")
    parser.add_argument('-d', '--data_dir', help="base dir of vco image data", required=True)
    parser.add_argument('-t', '--recording_type', help="type of recording (e.g., vco_pilot_run)", default="vco_pilot_run")
    args = parser.parse_args()
    vco_data_dir = os.path.abspath(os.path.dirname(args.data_dir))
    cur_rec_dir = os.path.abspath(args.rec_dir)
    validate_experiment_recording(cur_rec_dir, args.recording_type, vco_data_dir)
