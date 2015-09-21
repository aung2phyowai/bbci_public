#!/usr/bin/env python
""" combines two sequences by updating a range of frames of a base sequence with modified frames """

import argparse
import copy
import logging
import os
import re
import sys
import subprocess

feedback_path = os.path.normpath(os.path.join(os.path.dirname(__file__), "../feedbacks"))
sys.path.append(feedback_path)
import markers
import seq_file_utils


def _get_frame_numbers_from_dir(directory, printf_pattern):
    """extracts all frame numbers from directory based on a printf-style pattern"""
    #crude workaround, we assume that only %d appears
    regex = re.compile(re.sub("%\d*d", "(\d+)", printf_pattern)) #pylint: disable=anomalous-backslash-in-string
    matches = (regex.match(f) for f in os.listdir(directory))
    return sorted([int(m.group(1)) for m in matches if m])

def _get_file_name_from_number(directory, printf_pattern, number):
    """returns an absolute path to the frame file with given number in the directory"""
    filename = os.path.join(directory, printf_pattern % number)
    return os.path.abspath(filename)

def _is_ancestor_directory(ancestor, descendant):
    """checks whether descendant is somewhere underneath ancestor in the file tree"""
    abs_ancestor = os.path.abspath(ancestor)
    abs_descendant = os.path.abspath(descendant)
    prefix = os.path.commonprefix([abs_ancestor, abs_descendant])

    return os.path.samefile(prefix, abs_ancestor)

def process_arguments(args):
    """ checks arguments for validity and fills in non-specified values with defaults/calculated ones """
    #version information
    if args.base_version is not None:
        args.base_seq_dir += '-v' + args.base_version
        args.target_seq_name += '-v' + args.base_version
    if args.target_version is not None:
        if re.search("-v\d+$", args.target_seq_name) is not None:
            # we already have version information, so we only append
            args.target_seq_name += args.target_version
        else:
            args.target_seq_name += '-v' + args.target_version


    args.base_seq_dir = os.path.realpath(os.path.expanduser(args.base_seq_dir))
    if not os.path.isdir(args.base_seq_dir):
        logging.error("cannot find base directory %s", args.base_seq_dir)
        return None
    args.base_seq_type = os.path.basename(os.path.dirname(args.base_seq_dir))
    args.base_seq_name = os.path.basename(args.base_seq_dir)

    if args.data_root_dir is None:
        #expect image-root directory two levels up (image-root/*/c01_1...)
        args.data_root_dir = os.path.dirname(os.path.dirname(os.path.dirname(args.base_seq_dir)))
    args.images_dir = os.path.join(args.data_root_dir, "images")
    args.seq_file_root_dir = os.path.join(args.data_root_dir, "seqs")
    if not os.path.isdir(args.images_dir) or not os.path.isdir(args.seq_file_root_dir):
        logging.error("missing images and seq directory. make sure, your data root (%s) is correct", args.data_root_dir)
        return None

    args.modified_frames_dir = os.path.realpath(os.path.expanduser(args.modified_frames_dir))
    if not os.path.isdir(args.modified_frames_dir):
        logging.error("cannot find modified frames directory %s", args.modified_frames_dir)
        return None

    args.modified_frame_files_numbers = _get_frame_numbers_from_dir(args.modified_frames_dir, args.image_file_pattern)
    if not args.modified_frame_files_numbers:
        logging.error("cannot find any files matching the pattern %s in modified frames directory %s",
                      args.image_file_pattern, args.modified_frames_dir)
        return None

    if args.update_start_frame_no is None:
        args.update_start_frame_no = min(args.modified_frame_files_numbers)

    if args.update_end_frame_no is None:
        args.update_end_frame_no = max(args.modified_frame_files_numbers)

    args.base_frame_file_numbers = _get_frame_numbers_from_dir(args.base_seq_dir, args.image_file_pattern)
    if args.update_start_frame_no not in args.base_frame_file_numbers:
        logging.error("cannot find start frame %d in base dir %s", args.update_start_frame_no, args.base_seq_dir)
        return None

    if args.modified_event_marker not in markers.stimuli:
        logging.error("cannot find stimulus marker with name '%s'", args.modified_event_marker)
        return None

    #build update label
    args.target_seq_label = args.target_seq_name.split('-')[0]
    args.update_label = '-'.join(["E", args.update_label_type,
                                  args.target_seq_label,
                                  str(args.update_start_frame_no)])


    args.target_seq_dir = os.path.realpath(os.path.join(args.images_dir, args.sequence_type, args.target_seq_name))
    if os.path.exists(args.target_seq_dir):
        logging.warning("target directory exists: %s", args.target_seq_dir)
    else:
        logging.debug("creating target directory: %s", args.target_seq_dir)
        os.makedirs(args.target_seq_dir)
    args.seq_file_target_dir = os.path.join(args.seq_file_root_dir, args.sequence_type)
    args.seq_file_target = os.path.join(args.seq_file_target_dir,
                                        'seq_' + args.target_seq_name + '.txt')

    return args

def combine_sequences(args):
    """ performs the main combination work """
    args = process_arguments(args)
    if args is None:
        print "Illegal arguments"
        exit(1)

    #check whether we have a base seq file
    base_seq_file = os.path.join(args.seq_file_root_dir, args.base_seq_type,
                                 'seq_' + args.base_seq_name + '.txt')
    if os.path.isfile(base_seq_file):
        seq_file_data = seq_file_utils.load_seq_file(base_seq_file)
    else:
        seq_file_data = [seq_file_utils.SeqFileEntry(args.image_file_pattern % i) for i in args.base_frame_file_numbers]


    for (i, frame_no) in enumerate(args.base_frame_file_numbers):
        target_file = os.path.join(args.target_seq_dir, args.image_file_pattern % frame_no)
        if frame_no in args.modified_frame_files_numbers:
            #use updated frame
            source_file = _get_file_name_from_number(args.modified_frames_dir, args.image_file_pattern, frame_no)
            seq_file_data[i].event_names.append(args.update_label)
            if frame_no == args.modified_frame_files_numbers[0]:
                #first frame of modification, so we add a marker
                seq_file_data[i].marker_tuples.append(
                    (markers.stimuli[args.modified_event_marker],
                     args.modified_event_marker))
        else:
            source_file = _get_file_name_from_number(args.base_seq_dir, args.image_file_pattern, frame_no)

        if os.path.islink(source_file):
            #we eliminate one level of linking if we have a link to another image directory
            #os.readlink is recursive, but we want to resolve only one level, so use command instead
            link_target = subprocess.check_output(['readlink', source_file]).strip()
            source_file_target = os.path.normpath(os.path.join(os.path.dirname(source_file), link_target))
            if _is_ancestor_directory(args.images_dir, source_file_target):
                source_file = source_file_target

        rel_path_to_source = os.path.relpath(source_file, args.target_seq_dir)
        logging.debug("linking %s to %s", target_file, rel_path_to_source)
        if os.path.lexists(target_file):
            logging.warn("replacing existing file %s", target_file)
            os.unlink(target_file)
        os.symlink(rel_path_to_source, target_file)

        seq_file_data[i].file_name = os.path.relpath(target_file, args.seq_file_target_dir)

    seq_file_utils.write_seq_file(seq_file_data, args.seq_file_target)

if __name__ == "__main__":
    expected_label_prefixes = ['safe', 'uncertain', 'hazard']

    parser = argparse.ArgumentParser(description="combine a sequence with a modified image folder to create an updated one")
    parser.add_argument('target_seq_name', help='name of the newly created sequence')
    parser.add_argument('-l', '--category-label', required=True, dest='update_label_type',
                        help='label of the update, should usually be one of %s' % expected_label_prefixes)
    parser.add_argument('base_seq_dir', help='directory of the sequence to be updated')
    parser.add_argument('modified_frames_dir', help='directory with the updated frames')
    parser.add_argument('-t', '--sequence-type', dest='sequence_type', default='intermediate',
                        choices=['base', 'intermediate', 'final'], help='type of the newly generated sequence')
    parser.add_argument('-bv', '--base-version', dest='base_versions', action='append',
                        help='combine with each of these versions of the base sequence')
    parser.add_argument('-tv', '--target-version', dest='target_version',
                        help='add this version information to the output name, combining it with possible base versions')
    parser.add_argument('-m', '--modified-event-marker', dest='modified_event_marker',
                        default='generic_stimulus', help='marker to be placed at the first frame of the updated part')
    parser.add_argument('--update-start-frame-no', dest='update_start_frame_no',
                        type=int, help='frame number of the first update frame')
    parser.add_argument('--update-end-frame-no', dest='update_end_frame_no',
                        type=int, help='frame number of the last update frame')
    parser.add_argument('--image-file-pattern', dest='image_file_pattern',
                        default='%010d.png', help='pattern for image file names in printf format')
    parser.add_argument('--data-root-dir', dest='data_root_dir',
                        help="data directory with images and seqs as subfolders." +
                        " inferred from base_seq_dir if not specified")


    shell_args = parser.parse_args()
    if shell_args.update_label_type not in expected_label_prefixes:
        logging.warning('label type %s is not one of the expected:  %s',
                        shell_args.update_label_type, expected_label_prefixes)


    if shell_args.base_versions:
        for base_version in shell_args.base_versions:
            cur_args = copy.deepcopy(shell_args)
            cur_args.base_version = base_version
            combine_sequences(cur_args)
            seq_file_utils.validate_seq_file(cur_args.seq_file_target)
            print "generated sequence %s" % cur_args.target_seq_name
    else:
        shell_args.base_version = None
        combine_sequences(shell_args)
        seq_file_utils.validate_seq_file(shell_args.seq_file_target)
        print "generated sequence %s" % shell_args.target_seq_name
