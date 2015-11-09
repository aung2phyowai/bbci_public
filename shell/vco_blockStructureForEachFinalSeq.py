#!/bin/env python
import os
import sys

seqfiles_dir = sys.argv[1]
block_length = 12
fps = 10
#relative to vco data dir
relative_to = os.path.dirname(os.path.dirname(os.path.dirname(seqfiles_dir)))

available_seqs = [os.path.relpath(os.path.join(seqfiles_dir, f), relative_to)
                  for f in os.listdir(seqfiles_dir)]

print '\t'.join(["blockNo", "seqName", "FPS", "type"])

for i, seq_name in enumerate(available_seqs):
    block_no = int(i / block_length)
    if os.path.basename(seq_name).startswith('s'):
        seq_type = "simple"
    else:
        seq_type = "complex"
    print '\t'.join([str(block_no), seq_name, str(fps), seq_type])
