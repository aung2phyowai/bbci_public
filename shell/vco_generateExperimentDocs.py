#!/usr/bin/env python
""" Generates documents for the experiments based on the block structure"""

import argparse
import os

import block_structure_utils

def generateComplexityTable(block_structure, target_file, sep='\t'):
    with open(target_file, 'w') as fp:
        fp.write(sep.join(["block_no", "seq_no", "seq_name", "subject_complexity_rating"]) + '\n')
        for block_no, block in enumerate(block_structure):
            for seq_no, block_entry in enumerate(block):
                fp.write(sep.join([str(block_no), str(seq_no), block_entry.seq_name, '-1']))
                fp.write('\n')



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='generate documents and tables for recording subject ratings during an experiment')
    parser.add_argument('block_structure_file', help='block structure file')
    parser.add_argument('-o', '--output_directory', help="target directory for output")
    args = parser.parse_args()
    out_dir = os.path.abspath(args.output_directory)
    complexity_table_file = os.path.join(out_dir, 'complexity_table.tsv')
    bs = block_structure_utils.load_block_structure(args.block_structure_file)
    generateComplexityTable(bs, complexity_table_file)
