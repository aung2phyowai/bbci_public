#!/usr/bin/env python

"""
script to generate sequence block structure and calculate its statistics
"""

import argparse
import collections
import itertools
import logging
import math
import os
import random
import sys

import vco_sequenceStats

"""
data structure:
we have three levels : type - scene - version
assume, that we have only one (the final) modification (i.e., we ignore the mod-part)
"""

MAX_SUBSEQ_IDENT_TYPES = 3
FPS = 10

#--- utility functions---
def mean(num_list):
    """returns numeric mean of a list"""
    return float(sum(num_list)) / len(num_list)

def min_ctr_value(ctr):
    """returns the lowest value of all counter entries"""
    return ctr.most_common()[-1][1]

def max_ctr_value(ctr):
    """returns the highest value of all counter entries"""
    return ctr.most_common(1)[0][1]

def mean_ctr_value(ctr):
    """returns the mean count of all counter entries"""
    ctr_values = [e[1] for e in ctr.most_common()]
    return mean(ctr_values)



#--- domain code ---

def print_block_structure_stats(blocks):
    """    read block structure file and the referenced seq files
    calculate inter-scene distances
    warn if two identical are in the same block
    calculate which events are duplicates and used how often
     -> use this and/or name of sequence
    """
    labels_flattened = [seq['label'] for seq in itertools.chain.from_iterable(blocks)]
    structure_stats = []
    scene_ctr = collections.Counter() #keys are labels (e.g., c10_1)
    seq_ctr = collections.Counter() #keys are labels+version (e.g., c10_1-v01)
    type_ctr = collections.Counter()
    event_type_ctr = collections.Counter()
    for block_no, block in enumerate(blocks):
        block_stats = []
        for seq_in_block_no, seq in enumerate(block):
            total_no = block_no * len(block) + seq_in_block_no
            seq_stats = {}
            seq_stats.update(seq)
            type_ctr[seq['type']] += 1
            scene_ctr[seq['label']] += 1
            seq_ctr[seq['label'] + seq['version']] += 1
            try:
                seq_stats['inter_scene_dist'] = labels_flattened[(total_no + 1):].index(seq['label']) + 1
            except ValueError:
                seq_stats['inter_scene_dist'] = float('inf') #len(blocks) * len(block) + 1
            
            event_type_ctr += seq_stats['event_type_counts']
            block_stats.append(seq_stats)
        structure_stats.append(block_stats)
    print "Structure stats\n==============="


    event_types = sorted(list(event_type_ctr.keys()))

    t1_header_fmt_str = "|{:^8}|{:^5}|{:^4}|" + ("{:^9}|" * len(event_types))
    t1_line_fmt_str = "|{label:<8}|{version:<5}|{inter_scene_dist:>4}|"
    for t in event_types:
        t1_line_fmt_str += "{%s:>9}|" % t
    t1_hline = "|{:-<8}+{:-<5}+{:-<4}".format('', '', '') +  ("+{:-<9}".format('') * len(event_types)) + "|"
    print t1_header_fmt_str.format('scene', 'v', 'next', *event_types)
    for block_stats in structure_stats:
        print t1_hline
        for seq_stats in block_stats:
            for t in event_types:
                seq_stats[t] = seq_stats['event_type_counts'][t]
            print t1_line_fmt_str.format(**seq_stats)
    print t1_hline + "\n"
    print "\n"
    t2_header_fmt_str = "|{:^25}|{:^5}|{:^6}|"
    t2_line_fmt_str = "|{:<25}|{:<5}|{:>6.2f}|"
    t2_hline = "|{:-<25}+{:-<5}+{:-<6}|".format('', '', '')
    print t2_header_fmt_str.format('Summary', '', '')
    print t2_hline
    print t2_line_fmt_str.format('dupl. per scene', 'min', min_ctr_value(scene_ctr))
    print t2_line_fmt_str.format('', 'mean', mean_ctr_value(scene_ctr))
    print t2_line_fmt_str.format('', 'max', max_ctr_value(scene_ctr))
    print t2_hline
    print t2_line_fmt_str.format('dupl. per seq.', 'min', min_ctr_value(seq_ctr))
    print t2_line_fmt_str.format('', 'mean', mean_ctr_value(seq_ctr))
    print t2_line_fmt_str.format('', 'max', max_ctr_value(seq_ctr))
    print t2_hline
    inter_scene_dists = [ seqst['inter_scene_dist'] for blockst in structure_stats for seqst in blockst  if  seqst['inter_scene_dist'] < float('inf')]
    print t2_line_fmt_str.format('inter-scene-dists', 'min', min(inter_scene_dists))
    print t2_line_fmt_str.format('', 'mean', mean(inter_scene_dists))
    print t2_line_fmt_str.format('', 'max', max(inter_scene_dists))
    print t2_hline
    print t2_line_fmt_str.format('simple scenes', '', type_ctr['simple'])
    print t2_line_fmt_str.format('complex scenes', '', type_ctr['complex'])
    print t2_hline
    for t in event_types:
        print t2_line_fmt_str.format(t, '', event_type_ctr[t])
    print t2_hline

    

def extract_meta_from_name(filename):
    """read/generate metadata for the given sequence file"""
    basename = os.path.basename(filename)
    if not basename.startswith("seq_") or basename[4] not in ['s', 'c']:
        logging.error("unknown file name format %s", filename)
        return None
    seq_name = os.path.splitext(basename[4:])[0]
    seq_name_parts = seq_name.split('-')

    seq_meta = {}
    seq_meta['file_path'] = os.path.abspath(filename)
    seq_meta['file_name'] = basename
    seq_meta['label'] = seq_name_parts[0]
    seq_meta['group'] = seq_meta['label'].split('_')[0]
    if seq_name.startswith('s'):
        seq_meta['type'] = "simple"
    elif seq_name.startswith('c'):
        seq_meta['type'] = 'complex'
    else:
        logging.warn("unexpected type %s", seq_name[0])
    seq_meta['version'] = seq_name_parts[-1]
    if not seq_meta['version'].startswith('v'):
        seq_meta['version'] = 'vdef'

    seq_meta.update(vco_sequenceStats.calculate_single_seq_file_stat(seq_meta['file_path'], set()))
    return seq_meta

def select_seqs(target_count, available_seqs):
    """ Select the desired number of sequences by duplicating (if necessary)
         for duplication, different versions of a scene are preferred
    """
    seqs_by_scene = {}
    #group by scene (chained-lists)
    for seq in available_seqs:
        if seq['label'] in seqs_by_scene:
            seqs_by_scene[seq['label']].append(seq)
        else:
            seqs_by_scene[seq['label']] = [seq]
#    max_version_count = max((len(l) for l seqs_by_scene.values()))
    selected_seqs = []

    #sort scenes based on number of different versions of sequence and the number of events in the sequence (only taken from first version)
    seqs_by_scene = collections.OrderedDict(sorted(seqs_by_scene.items(), key=lambda e: (len(e[1]), sum(e[1][0]['event_type_counts'].values())), reverse=True))

    max_version_count = len(seqs_by_scene.values()[0])
    scene_ctr = collections.Counter()
    while len(selected_seqs) < target_count:
        for current_version_idx in range(max_version_count):
            for scene_label, seqs in seqs_by_scene.items():
                if len(selected_seqs) < target_count:
                    #we chose the current version, if available
                    selected_seqs.append(seqs[current_version_idx % len(seqs)])
                    scene_ctr[scene_label] += 1

    return selected_seqs



def generate_block_structure(seqfiles_dir, block_count, block_size):
    """generates the block structure based on available sequence files"""
    available_seqs = [extract_meta_from_name(os.path.join(seqfiles_dir, f)) for f in os.listdir(seqfiles_dir)]
    complex_seqs = [s for s in available_seqs if s['type'] == 'complex']
    simple_seqs = [s for s in available_seqs if s['type'] == 'simple']
    blocks = []

    no_seqs_per_type = math.ceil(block_count * block_size / 2)
    selected_complex_seqs = select_seqs(no_seqs_per_type, complex_seqs)
    selected_simple_seqs = select_seqs(no_seqs_per_type, simple_seqs)

  #  print '\n'.join([seq['label'] + "\t" +  seq['version'] for seq in selected_complex_seqs])
   # print '\n'.join([seq['label'] + "\t" +  seq['version'] for seq in selected_simple_seqs])

    #make deterministic
    random.seed(0)


    #v1 simple
    for i in range(block_count):
        cur_block = []
        start_idx_per_type = i * block_size / 2
        end_idx_per_type = start_idx_per_type + (block_size / 2)
        cur_block.extend(selected_simple_seqs[start_idx_per_type:end_idx_per_type])
        cur_block.extend(selected_complex_seqs[start_idx_per_type:end_idx_per_type])
        random.shuffle(cur_block)

        #some heuristic reodering

        # 1. spread sequences of same group
        # 2. we don't want more than MAX_SUBSEQ_IDENT_TYPES of same type in a row

        last_type = None
        type_count = 0
        last_group = None
        for j in range(block_size):
            #first, look at type
            cur_type = cur_block[j]['type']
            if cur_type == last_type:
                type_count += 1
                if type_count >= MAX_SUBSEQ_IDENT_TYPES + 1:
                    try:
                        next_diff_type_idx = next((idx for (idx, seq) in enumerate(cur_block) if idx > j and seq['type'] != cur_type))
                        cur_block[j], cur_block[next_diff_type_idx] = cur_block[next_diff_type_idx], cur_block[j]
                        last_type = cur_block[j]['type']
                        type_count = 1
                    except StopIteration:
                        #no more other types, we don't switch
                        pass
            else:
                last_type = cur_type
                type_count = 1
            #second, look at group
            # we don't need to look at type, if we switched in this iteration, we certainly have a new group
            cur_group = cur_block[j]['group']
            if cur_group == last_group:
                try:
                    next_diff_group_idx = next((idx for (idx, seq) in enumerate(cur_block) if idx > j and seq['group'] != cur_group))
                    cur_block[j], cur_block[next_diff_group_idx] = cur_block[next_diff_group_idx], cur_block[j]
                    last_group = cur_block[j]['group']
                except StopIteration:
                    #no more other groups, don't switch
                    pass
            last_group = cur_block[j]['group']

        blocks.append(cur_block)
    return blocks

def write_block_structure(blocks, target_file, fps, resolve_relative_to):
    """write block-structure as tab-separated file"""
    header = ["blockNo", "seqName", "FPS", "type"]
    target_file.write('\t'.join(header) + '\n')
    for block_no, block in enumerate(blocks):
        for seq in block:
            resolved_file = os.path.relpath(seq['file_path'], resolve_relative_to)
            #start first block with 1 to leave room for manual insertion of block 0 for familarization
            line = [str(block_no + 1), resolved_file, str(fps), seq['type']]
            target_file.write('\t'.join(line) + '\n')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='script to generate sequence block structure and calculate its statistics')
    parser.add_argument('seqfiles_dir', help="directory with sequence files to be used. Type is inferred from the naming scheme")
    parser.add_argument('-o', '--out_file', help="output file for block structure", default=sys.stdout, type=argparse.FileType('w'))
    parser.add_argument('-r', '--relative_to', help="output sequence file names relative to this directory (default: working directory)", default=os.getcwd())
    parser.add_argument('-bc', '--block_count', help="number of blocks", type=int, default=20)
    parser.add_argument('-bl', '--block_length', help="length of (number of sequences in) each block", type=int, default=12)
    parser.add_argument('-fps', help="FPS rate for sequence playback", type=int, default=10)
    parser.add_argument('-q', '--quiet', help="do not print statistics", action='store_true')
    args = parser.parse_args()
    
    gen_blocks = generate_block_structure(args.seqfiles_dir, args.block_count, args.block_length)
    if not args.quiet:
        print_block_structure_stats(gen_blocks)
    write_block_structure(gen_blocks, args.out_file, args.fps, args.relative_to)
