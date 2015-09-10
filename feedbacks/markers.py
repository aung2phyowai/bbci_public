"""
    The marker constants used for visual complexity feedback.
    Definitions are loaded from the ini file on import of the module

    Each section of the ini file is an attribute of the module
     and contains a dictionary with the corresponding item.

    Example
     import markers
     send_marker(markers.technical['trial_start']))
"""
#pylint: disable=invalid-name

import collections
import os
import ConfigParser

#define placeholders to prevent pylint errors in using code
stimuli = {}
technical = {}
interactions = {}

marker_groups = []
marker_version = None

def _load_marker_ini(marker_file):
    """ loads marker definitions from ini file
         each section of the ini file is converted to an attribute
         of the current module
    """
    config = ConfigParser.ConfigParser()
    config.read(marker_file)
    globals()['marker_version'] = config.getint("meta", "version")
    inverse_counter = collections.Counter()
    sections = [s for s in config.sections() if s != "meta"]
    for section_name in sections:
        marker_groups.append(section_name)
        items = config.items(section_name)
        items_dict = dict([(name, int(value)) for name, value in items])
        globals()[section_name] = items_dict
        inverse_counter.update(items_dict.values())
    duplicate_values = [value for value, count in inverse_counter.items() if count > 1]
    if duplicate_values:
        raise ValueError("duplicate marker values: %s" % duplicate_values)

# executed on first access
_load_marker_ini(os.path.normpath(os.path.join(
    os.path.dirname(__file__), "../config/markers.ini")))
