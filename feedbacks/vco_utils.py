"""Generic utility functions"""
import logging
import os
import pickle

def parse_matlab_char_array(char_array):
    """convert char array to string"""
    characters = [chr(int(i)) for i in char_array]
    return ''.join(characters)

def get_pyff_path(vco_repo_dir):
    """tries to parse the pyff repo dir from the matlab config file"""
    local_setup_file = os.path.join(vco_repo_dir, 'config', 'local_setup.m')
    print "vco repo %s " % vco_repo_dir
    print "file %s" % local_setup_file
    with open(local_setup_file, 'r') as f:
        pyff_lines = [l.split("'") for l in f if 'PROJECT_SETUP.PYFF_DIR' in l]
        #we want the value, i.e. the part within single quotes
        if pyff_lines and len(pyff_lines[0]) > 1:
            return (pyff_lines[0])[1]
        else:
            return None

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

def setup_logging_handlers(logger_name, config):
    """setup debug and warning logging handlers """
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.DEBUG)
    existing_targets = [hdl.baseFilename for hdl in logger.handlers if "baseFilename" in dir(hdl)]
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    for name, level in [("debug", logging.DEBUG), ("warning", logging.WARNING)]:
        log_filepath = os.path.join(config['log_dir'],
                                    '_'.join([config['start_date_string'],
                                              config['log_prefix'],
                                              logger_name, name]) + ".log")
        if log_filepath not in existing_targets:
            handler = logging.FileHandler(log_filepath)
            handler.setLevel(level)
            handler.setFormatter(formatter)
            logger.addHandler(handler)
    
