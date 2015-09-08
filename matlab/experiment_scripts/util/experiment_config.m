function experiment_config()
% set and generate configuration settings for this experiment

global EXPERIMENT_CONFIG
global PROJECT_SETUP %read-only, not being modified

subject_config(); %source VP code etc


%% configuration

%type of block structure:

%number of sequences to play per complexity type
EXPERIMENT_CONFIG.seqsPerType = 12;
%number of sequences per block
EXPERIMENT_CONFIG.blockSize = 2;
EXPERIMENT_CONFIG.sequences.randomize = false;
%whether scenes of different complexity should be mixed in a block
EXPERIMENT_CONFIG.mixComplexitiesWithinBlocks = true;

EXPERIMENT_CONFIG.VPcode_date = [EXPERIMENT_CONFIG.VPcode '_' EXPERIMENT_CONFIG.date];
EXPERIMENT_CONFIG.filePrefix = [EXPERIMENT_CONFIG.VPcode_date '_vco_pilot_run'];
EXPERIMENT_CONFIG.logging.enabled = false;
EXPERIMENT_CONFIG.validation.show_validation_stats = true;

EXPERIMENT_CONFIG.feedback.use_optomarker = true;

%%%%%%%%%%%%%%%%%%%%%%%
% from this point on, the configuration should [usually] not be changed

%validation of block structure
EXPERIMENT_CONFIG.block_count = 2*EXPERIMENT_CONFIG.seqsPerType / EXPERIMENT_CONFIG.blockSize;
if EXPERIMENT_CONFIG.mixComplexitiesWithinBlocks && mod(2*EXPERIMENT_CONFIG.seqsPerType, EXPERIMENT_CONFIG.blockSize) ~= 0
    error('block size is not divisor of total seq number')
end
if ~EXPERIMENT_CONFIG.mixComplexitiesWithinBlocks && mod(EXPERIMENT_CONFIG.seqsPerType, EXPERIMENT_CONFIG.blockSize) ~= 0
    error('block size is not divisor of seq number per type')
end

if ~EXPERIMENT_CONFIG.mixComplexitiesWithinBlocks && mod(EXPERIMENT_CONFIG.block_count, 2) ~= 0
    error('need to have even block size if complexitites are not mixed')
end

EXPERIMENT_CONFIG.recordDir = fullfile(PROJECT_SETUP.BBCI_DATA_DIR, EXPERIMENT_CONFIG.VPcode_date);
EXPERIMENT_CONFIG.feedbackLogDir = fullfile(EXPERIMENT_CONFIG.recordDir, 'feedback_logs');

EXPERIMENT_CONFIG.markers = ini2struct(fullfile(PROJECT_SETUP.CONFIG_DIR, 'markers.ini'));

%initialize RNG based on VPcode and date -> identical order on each run
reset_rng()

complexSeqListFile = fullfile(PROJECT_SETUP.CONFIG_DIR, 'complex_seqs.txt');
simpleSeqListFile = fullfile(PROJECT_SETUP.CONFIG_DIR, 'simple_seqs.txt');

EXPERIMENT_CONFIG.simpleSeqs = load_seq_list(simpleSeqListFile);
if size(EXPERIMENT_CONFIG.simpleSeqs, 1) < EXPERIMENT_CONFIG.seqsPerType
    error(['not enough simple scenes ', ...
        num2str(size(EXPERIMENT_CONFIG.simpleSeqs, 1)), '/', num2str(EXPERIMENT_CONFIG.scenesPerType)])
end
EXPERIMENT_CONFIG.complexSeqs = load_seq_list(complexSeqListFile);
if size(EXPERIMENT_CONFIG.complexSeqs, 1) < EXPERIMENT_CONFIG.seqsPerType
    error(['not enough complex scenes ', ...
        num2str(size(EXPERIMENT_CONFIG.complexSeqs, 1)), '/', num2str(EXPERIMENT_CONFIG.scenesPerType)])
end

% build the actual structure
EXPERIMENT_CONFIG.blockStructure = build_block_structure();

evalin('base', 'global EXPERIMENT_CONFIG');

EXPERIMENT_CONFIG %#ok<NOPRT>

%% utility functions

    function seqList = load_seq_list(filePath)
        seqList = table2cell(readtable(filePath,...
        'Delimiter', '\t',...    
        'ReadVariableNames', false));
    end


end