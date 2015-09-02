"""Utility functions for ImageSeqViewer"""
import os
import pickle
import ConfigParser

import markers
def load_seq_file(image_seq_file):
    """
    load a file containing an image sequence
     expected format
      ${relativeFileName}\t${optionalMarker1}\t${optionalMarkerN}
     the file format can easily be created with e.g.,
      ls -1 ../original/2011_10_03_drive_0047_sync/image_02/data/*
     lines starting with # are ignored
    """

    #auxiliary function
    def process_marker(marker_str):
        """process markers (integers or names) in sequence file"""
        try:
            return int(marker_str)
        except ValueError:
            if marker_str in markers.stimuli:
                return markers.stimuli[marker_str]
            else:
                return markers.stimuli['generic_event']
    def parse_line(line):
        """process single line in sequence file"""
        fields = line.rstrip('\n').split('\t')
        #resolve image path relative to file
        file_name = os.path.join(os.path.dirname(image_seq_file), os.path.normpath(fields[0]))
        return (file_name, [process_marker(marker_string) for marker_string in fields[1:]])

    # do the actual work
    return [parse_line(l) for l in open(image_seq_file) if not l.lstrip().startswith('#')]


def parse_matlab_char_array(char_array):
    """convert char array to string"""
    characters = [chr(int(i)) for i in char_array]
    return ''.join(characters)

def dump_settings(object_to_pickle, pickle_file_name):
    """Dumps all pickable attribute of the object to the supplied file"""
    # Determine the pickable attributes of the feedback and store them
    attr_all = dir(object_to_pickle)
    attr_to_pickle = {}

    #filter out private attributes?
    out_file = open(pickle_file_name, 'wb')
    valid_keys = []
    for cur_att in attr_all:
        val = getattr(object_to_pickle, cur_att)
        if not hasattr(val, '__call__'):
            try:
                attr_to_pickle[cur_att] = getattr(object_to_pickle, cur_att)
                pickle.dump(attr_to_pickle, out_file)
                valid_keys.append(cur_att)
            except: #pylint: disable=bare-except
                del attr_to_pickle[cur_att]
    out_file.seek(0)
    pickle.dump(attr_to_pickle, out_file)
