#!/usr/bin/env python
""" calculates statistics based on event markers in sequence files"""

import argparse
import collections
import os
import sys

feedback_path = os.path.normpath(os.path.join(os.path.dirname(__file__), "../feedbacks"))
sys.path.append(feedback_path)
import seq_file_utils

def calculate_single_seq_file_stat(seq_file, seen_frame_files):
    """calculates statistics for a single sequence file"""
    parsed_seq = seq_file_utils.load_seq_file(seq_file)
    event_names = {name for frame in parsed_seq for name in frame.event_names}

    event_type_ctr = collections.Counter()
    for event_name in event_names:
        #naming scheme is E-hazard-c10-...
        event_type = event_name.split('-')[1]
        event_type_ctr[event_type] += 1

    frame_files = {os.path.realpath(frame.file_name) for frame in parsed_seq}
    new_files = frame_files - seen_frame_files
    seen_frame_files |= new_files
    return {'name' : seq_file,
            'event_type_counts' : event_type_ctr,
            'frame_count' : len(frame_files),
            'new_frames' :  len(new_files),
            'event_names' : event_names}

def calculate_full_stat(seq_file_list):
    """calculates individual and total statics for all supplied seq files """
    total_frame_count = 0
    total_event_type_counts = collections.Counter()
    seen_frame_files = set()
    single_file_stats = []
    for seq_file in seq_file_list:
        seq_file_stats = calculate_single_seq_file_stat(seq_file, seen_frame_files)
        single_file_stats.append(seq_file_stats)
        total_frame_count += seq_file_stats['frame_count']
        total_event_type_counts += seq_file_stats['event_type_counts']
    total_stats = {
                   'frame_count' : total_frame_count,
                   'event_type_counts' : total_event_type_counts,
                   'new_frames' : len(seen_frame_files)}
    return {'single_stats' : single_file_stats,
            'total_stats' : total_stats}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='calculate statistics based on event markers in sequence files')
    #parser.add_argument('seqFiles', nargs='*', default=[ '~/local_data/kitti/seqs/seq_s03_1-hardtwaldb.txt'])
    parser.add_argument('seqFiles', nargs='+')

    args = parser.parse_args()

    stats = calculate_full_stat(args.seqFiles)

    event_types = sorted(list(stats['total_stats']['event_type_counts'].keys()))
    #build format strings
    fmt_header = "|{:^50}|{:^8}|{:^8}|"
    hline =  "|{:-<50}+{:-<8}+{:-<8}".format('', '', '')
    fmt_body = "|{name:<50}|{new_frames:>8d}|{frame_count:>8d}|"
    for event_type in event_types:
        fmt_header += "{:^9}|"
        fmt_body += "{%s:>9d}|" % event_type
        hline += "+{:-<9}".format('')
    hline += "|"

  
    print fmt_header.format('sequence', 'uniq fr', 'tot fr', *event_types)
    print hline

    for file_stat in stats['single_stats']:
        for t in event_types:
            file_stat[t] = file_stat['event_type_counts'][t]
        print fmt_body.format(**file_stat)
    print hline

    for t in event_types:
        stats['total_stats'][t] = stats['total_stats']['event_type_counts'][t]
    print fmt_body.format(name="total", **stats['total_stats'])
