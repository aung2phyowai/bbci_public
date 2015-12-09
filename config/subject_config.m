function subject_config()
%subject_config Set VPcode etc

global EXPERIMENT_CONFIG

EXPERIMENT_CONFIG.VPcode = 'VPtest';
EXPERIMENT_CONFIG.date = datestr(now, 'yy-mm-dd');