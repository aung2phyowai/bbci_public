#!/usr/bin/env python
""" calculates statistics based on event markers in sequence files"""

import argparse
import os
import sys

feedback_path = os.path.normpath(os.path.join(os.path.dirname(__file__), "../feedbacks"))
sys.path.append(feedback_path)
import seq_file_utils

def calculate_single_seq_file_stat(seq_file, seen_frame_files):
    """calculates statistics for a single sequence file"""
    parsed_seq = seq_file_utils.load_seq_file(seq_file)
    event_names = {name for frame in parsed_seq for name in frame.event_names}
    hazard_count = len([e for e in event_names if e.startswith('E-hazard')])
    safe_count = len([e for e in event_names if e.startswith('E-safe')])

    frame_files = {os.path.realpath(frame.file_name) for frame in parsed_seq}
    new_files = frame_files - seen_frame_files
    seen_frame_files |= new_files
    return {'name' : seq_file,
            'hazard_count' : hazard_count,
            'safe_count' : safe_count,
            'new_frames' :  len(new_files)}

def calculate_full_stat(seq_file_list):
    """calculates individual and total statics for all supplied seq files """
    total_hazard_count = 0
    total_safe_count = 0
    seen_frame_files = set()
    single_file_stats = []
    for seq_file in seq_file_list:
        seq_file_stats = calculate_single_seq_file_stat(seq_file, seen_frame_files)
        single_file_stats.append(seq_file_stats)
        total_hazard_count += seq_file_stats['hazard_count']
        total_safe_count += seq_file_stats['safe_count']
    total_stats = {'total_hazard_count': total_hazard_count,
                   'total_safe_count': total_safe_count,
                   'seen_frame_files_no' : len(seen_frame_files)}
    return {'single_stats' : single_file_stats,
            'total_stats' : total_stats}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='calculate statistics based on event markers in sequence files')
    #parser.add_argument('seqFiles', nargs='*', default=[ '~/local_data/kitti/seqs/seq_s03_1-hardtwaldb.txt'])
    parser.add_argument('seqFiles', nargs='+')

    args = parser.parse_args()

    stats = calculate_full_stat(args.seqFiles)

    print "|{:^50}|{:^8}|{:^8}|{:^8}|".format('sequence', 'E-hazard', 'E-safe', 'uniq fr')
    print "|{:-<50}+{:-<8}+{:-<8}+{:-<8}|".format('', '', '', '')

    for file_stat in stats['single_stats']:
        print "|{name:<50}|{hazard_count:>8d}|{safe_count:>8d}|{new_frames:>8d}|".format(**file_stat)

    print "|{:-<50}+{:-<8}+{:-<8}+{:-<8}|".format('', '', '', '')
    print "|{:<50}|{total_hazard_count:>8d}|{total_safe_count:>8d}|{seen_frame_files_no:>8d}|".format('Sum', **stats['total_stats'])
