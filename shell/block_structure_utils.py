""" Utility functions for dealing with block structure files"""

import collections
import csv
import os

BlockEntry = collections.namedtuple('BlockEntry', ['seq_name', 'seq_file', 'fps', 'seq_type'])

def load_block_structure(bs_file, vco_data_dir=None):
    """reads a block structure file into a list of 'BlockEntry's """
    blocks = collections.OrderedDict()
    with open(bs_file) as fp:
        tsv_reader = csv.reader(fp, delimiter='\t')
        next(tsv_reader) #skip header
        last_block_no = -1
        for row in tsv_reader:
            block_no = int(row[0])
            if block_no != last_block_no:
                blocks[block_no] = []
                last_block_no = block_no
            seq_basename = os.path.basename(os.path.normpath(row[1]))
            if vco_data_dir:
                seq_file_name = os.path.normpath(os.path.join(vco_data_dir, row[1]))
            else:
                seq_file_name = None
            seq_fps = int(row[2])
            seq_type = row[3]
            blocks[block_no].append(BlockEntry(
                seq_basename, seq_file_name, seq_fps, seq_type))
    return blocks
