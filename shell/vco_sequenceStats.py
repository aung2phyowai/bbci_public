#!/usr/bin/env python
""" calculates statistics based on event markers in sequence files"""

import argparse
import os
import sys

feedback_path = os.path.normpath(os.path.join(os.path.dirname(__file__), "../feedbacks"))
sys.path.append(feedback_path)
import seq_file_utils

if __name__ == "__main__":
   
    parser = argparse.ArgumentParser(description='calculate statistics based on event markers in sequence files')
    #parser.add_argument('seqFiles', nargs='*', default=[ '~/local_data/kitti/seqs/seq_s03_1-hardtwaldb.txt'])
    parser.add_argument('seqFiles', nargs='+')

    args = parser.parse_args()

    print "|{:^50}|{:^8}|{:^8}|{:^8}|".format('sequence', 'E-hazard', 'E-safe', 'uniq fr')
    print "|{:-<50}+{:-<8}+{:-<8}+{:-<8}|".format('', '', '', '')

    total_hazard_count = 0
    total_safe_count = 0
    seen_frame_files = set()
    for seqFile in args.seqFiles:
        parsed_seq = seq_file_utils.load_seq_file(seqFile)
        event_names = {name for frame in parsed_seq for name in frame[2]}
        hazard_count = len([e for e in event_names if e.startswith('E-hazard')])
        safe_count = len([e for e in event_names if e.startswith('E-safe')])

        frame_files = {os.path.realpath(frame[0]) for frame in parsed_seq}
        new_files = frame_files - seen_frame_files
        seen_frame_files |= new_files

        total_hazard_count += hazard_count
        total_safe_count += safe_count
        print "|{:<50}|{:>8d}|{:>8d}|{:>8d}|".format(seqFile, hazard_count, safe_count, len(new_files))

    print "|{:-<50}+{:-<8}+{:-<8}+{:-<8}|".format('', '', '', '')
    print "|{:<50}|{:>8d}|{:>8d}|{:>8d}|".format('Sum', total_hazard_count, total_safe_count, len(seen_frame_files))
