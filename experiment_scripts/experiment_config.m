function experiment_config()

global EXPERIMENT_CONFIG
global PROJECT_SETUP %read-only, not being modified

subject_config(); %source VP code etc


%% configuration

EXPERIMENT_CONFIG.VPcode_date = [EXPERIMENT_CONFIG.VPcode '_' EXPERIMENT_CONFIG.date]
EXPERIMENT_CONFIG.filePrefix = ['vco_pilot_run_' EXPERIMENT_CONFIG.VPcode_date];
EXPERIMENT_CONFIG.logging.enabled = false;
EXPERIMENT_CONFIG.validation.show_validation_stats = true;
EXPERIMENT_CONFIG.sequences.randomize = true;

EXPERIMENT_CONFIG.feedback.use_optomarker = true;
EXPERIMENT_CONFIG.feedback.image_size = [1242, 375];

%%%%%%%%%%%%%%%%%%%%%%%
% from this point on, the configuration should [usually] not be changed


EXPERIMENT_CONFIG.markers = marker_definitions();

%initialize RNG based on VPcode and date -> identical order on each run
vpSeed = java.lang.Math.abs(java.lang.String(strcat(...
    EXPERIMENT_CONFIG.VPcode, EXPERIMENT_CONFIG.date)).hashCode());
rng(vpSeed)

complexSeqListFile = fullfile(PROJECT_SETUP.CONFIG_DIR, 'complex_seqs.txt');
simpleSeqListFile = fullfile(PROJECT_SETUP.CONFIG_DIR, 'simple_seqs.txt');

EXPERIMENT_CONFIG.simpleSeqs = load_seq_list(simpleSeqListFile);
EXPERIMENT_CONFIG.complexSeqs = load_seq_list(complexSeqListFile);


evalin('base', 'global EXPERIMENT_CONFIG');

EXPERIMENT_CONFIG %#ok<NOPRT>

%% utility functions

    function seqList = load_seq_list(filePath)
        seqList = table2cell(readtable(filePath,...
        'Delimiter', '\t',...    
        'ReadVariableNames', false));
    end


end