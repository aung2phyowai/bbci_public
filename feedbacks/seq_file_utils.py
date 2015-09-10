"""Utility functions for dealing with sequence files """

import collections
import os
import markers


Marker = collections.namedtuple('Marker', ['value', 'name'])

class SeqFileEntry(object):
    """ class representing a single line in the sequence file"""
    def __init__(self, file_name, marker_tuples=None, event_names=None):
        if marker_tuples is None:
            marker_tuples = []
        if event_names is None:
            event_names = []
        self.file_name = file_name
        self.marker_tuples = marker_tuples
        self.event_names = event_names

    def to_seq_file_line(self):
        """ converts this instance back to a sequence file line"""
        columns = [self.file_name]
        columns.extend(self.event_names)
        for marker in self.marker_tuples:
            if marker.name is not None:
                columns.append(marker.name)
            else:
                columns.append(marker.value)
        return '\t'.join(columns)

    @staticmethod
    def _process_marker(marker_str):
        """process markers (integers or names) in sequence file"""
        if marker_str in markers.stimuli:
            return Marker(markers.stimuli[marker_str], marker_str)
        else:
            try:
                return Marker(int(marker_str), None)
            except ValueError:
                return Marker(markers.stimuli['generic_stimulus'], 'generic_stimulus')

    @staticmethod
    def parse_line(line, path_reference):
        """process single line in sequence file """
        fields = line.rstrip('\n').split('\t')
        event_names = [s for s in fields[1:] if s.startswith('E')]
        marker_names = [s for s in fields[1:] if not s.startswith('E')]
        #resolve image path relative to file
        file_name = os.path.abspath(os.path.join(path_reference, os.path.normpath(fields[0])))
        return SeqFileEntry(file_name,
                            [SeqFileEntry._process_marker(marker_string) for marker_string in marker_names],
                            event_names)



def load_seq_file(image_seq_file):
    """
    load a file containing an image sequence
     expected format
      ${relativeFileName}\t${optionalEventName}\t${optionalMarker1}\t${optionalMarkerN}
     event names are characterized by starting with a capital E
     the file format can easily be created with e.g.,
      ls -1 ../original/2011_10_03_drive_0047_sync/image_02/data/*
     lines starting with # are ignored
    """

    # do the actual work
    return [SeqFileEntry.parse_line(l, os.path.dirname(image_seq_file))
            for l in open(image_seq_file) if not l.lstrip().startswith('#')]


def validate_seq_file(image_seq_file):
    """validates a seq file by trying to parse it and prints errors"""
    if len(markers.stimuli.values()) != len(set(markers.stimuli.values())):
        print("ERROR duplicate marker values in marker.ini")
        print("      found values %s in dictionary %s" % (sorted(markers.stimuli.values()), markers.stimuli))
    stimulus_marker_to_name = {marker: name for name, marker in markers.stimuli.items()}
    image_marker_list = load_seq_file(image_seq_file)
    for frame in image_marker_list:
        image_file = frame.file_name
        image_markers = frame.marker_tuples
        if not os.path.isfile(image_file):
            print("%s ERROR: cannot find image %s" % (image_seq_file, image_file))
        try:
            open(image_file)
        except IOError, e:
            print("%s ERROR: cannot open image %s (%s)" % (image_seq_file, image_file, e))
        for marker in image_markers:
            if marker.value not in stimulus_marker_to_name:
                print("%s ERROR: unknown stimulus marker %d at frame %s" % (image_seq_file, marker[0], image_file))
            if marker.value == markers.stimuli['generic_stimulus']:
                print("%s  WARN: using 'generic_stimulus' marker for frame %s" % (image_seq_file, image_file))
            if marker.name is None:
                print("%s  WARN: using purely numeric marker %d for frame %s" % (image_seq_file, marker[0], image_file))

def write_seq_file(seq_file_data, target_file):
    """ writes the data from a list of SeqFileEntry objects to a seq file """
    with open(target_file, 'w') as f:
        for entry in seq_file_data:
            f.write(entry.to_seq_file_line() + '\n')
