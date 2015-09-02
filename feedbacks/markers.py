"""
    The marker constants used for visual complexity feedback.
    Definitions are loaded from the ini file on import of the module

    Each section of the ini file is an attribute of the module and contains a dictionary with the corresponding item.

    Example
     import markers
     send_marker(markers.technical['trial_start']))
"""
import os
import ConfigParser
def _load_marker_ini(marker_file):
    """ loads marker definitions from ini file
         each section of the ini file is converted to an attribute of the current module
    """
    config = ConfigParser.ConfigParser()
    config.read(marker_file)
    for section_name in config.sections():
        items = config.items(section_name)
        items = [(name, int(value)) for name, value in items]
        globals()[section_name] = dict(items)
# executed on first access
_load_marker_ini(os.path.normpath(os.path.join(
    os.path.dirname(__file__), "../config/markers.ini")))
