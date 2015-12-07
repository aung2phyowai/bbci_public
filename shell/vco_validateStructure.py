#!/usr/bin/env python
import argparse
import csv
import os
import sys

feedback_path = os.path.normpath(os.path.join(os.path.dirname(__file__), "../feedbacks"))
sys.path.append(feedback_path)
import seq_file_utils

def validate_block_structure_file(bs_file, vco_data_dir):
    with open(bs_file) as fp:
        tsv_reader = csv.reader(fp, delimiter='\t')
        next(tsv_reader) #skip header
        for row in tsv_reader:
            seq_file_name = os.path.normpath(os.path.join(vco_data_dir, row[1]))
            # print "checking seq file '%s'" % seq_file_name
            seq_file_utils.validate_seq_file(seq_file_name)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='validate the existence of all image files of a block structure or sequence file')
    parser.add_argument('-d', '--data_dir', help="base dir of vco image data", required=True)
    parser.add_argument('-b', '--block_structure_files', help='block structure file to check', nargs='*', default=[])
    parser.add_argument('-s', '--sequence_files', help='sequence files to check', nargs='*', default=[])
    args = parser.parse_args()
    data_dir = os.path.abspath(os.path.dirname(args.data_dir))
    for seq_file in args.sequence_files:
        seq_file_utils.validate_seq_file(seq_file)
    for block_structure_file in args.block_structure_files:
        validate_block_structure_file(block_structure_file, data_dir)
