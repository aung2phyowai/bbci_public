function experiment_config()
% set and generate configuration settings for this experiment

global EXPERIMENT_CONFIG
global PROJECT_SETUP %read-only, not being modified

subject_config(); %source VP code etc


%% configuration

%type of block structure:


EXPERIMENT_CONFIG.block_structure_file = fullfile(PROJECT_SETUP.CONFIG_DIR, 'block_structure.tsv');

EXPERIMENT_CONFIG.VPcode_date = [EXPERIMENT_CONFIG.VPcode '_' EXPERIMENT_CONFIG.date];
EXPERIMENT_CONFIG.filePrefix = [EXPERIMENT_CONFIG.VPcode_date '_vco_pilot_run'];
EXPERIMENT_CONFIG.logging.enabled = false;
EXPERIMENT_CONFIG.validation.show_validation_stats = false;

% feedback settings
EXPERIMENT_CONFIG.fb.show_debug_infos = false;

EXPERIMENT_CONFIG.fb.img_seq.python_class_name = 'ImageSeqFeedback';
EXPERIMENT_CONFIG.fb.img_seq.use_optomarker = true;
EXPERIMENT_CONFIG.fb.img_seq.overlay_duration = 1.0;
EXPERIMENT_CONFIG.fb.img_seq.playback_delay = 5.0; %after receiving play state command

EXPERIMENT_CONFIG.fb.reaction_time.python_class_name = 'ReactionTimeFeedback';
EXPERIMENT_CONFIG.fb.reaction_time.enabled = false;
EXPERIMENT_CONFIG.fb.reaction_time.max_reaction_time = 2.0;
EXPERIMENT_CONFIG.fb.reaction_time.inter_stimulus_delay = 2.0;
EXPERIMENT_CONFIG.fb.reaction_time.min_readiness_duration = 1.0;
EXPERIMENT_CONFIG.fb.reaction_time.max_stimulus_jitter = 2.0;
EXPERIMENT_CONFIG.fb.reaction_time.block_length = 2;
EXPERIMENT_CONFIG.fb.reaction_time.block_count = 5;

%%%%%%%%%%%%%%%%%%%%%%%
% from this point on, the configuration should [usually] not be changed

% deprecated parameters for block structure generation (now set based on
% read data)
% %number of sequences to play per complexity type
% EXPERIMENT_CONFIG.seqsPerType = 20;
% %number of sequences per block
% EXPERIMENT_CONFIG.blockSize = 5;
% EXPERIMENT_CONFIG.sequences.randomize = true;
% %whether scenes of different complexity should be mixed in a block
% EXPERIMENT_CONFIG.mixComplexitiesWithinBlocks = true;



EXPERIMENT_CONFIG.recordDir = fullfile(PROJECT_SETUP.BBCI_DATA_DIR, EXPERIMENT_CONFIG.VPcode_date);
EXPERIMENT_CONFIG.feedbackLogDir = fullfile(EXPERIMENT_CONFIG.recordDir, 'feedback_logs');

EXPERIMENT_CONFIG.markers = ini2struct(fullfile(PROJECT_SETUP.CONFIG_DIR, 'markers.ini'));

[EXPERIMENT_CONFIG.block_structure, EXPERIMENT_CONFIG.block_count, EXPERIMENT_CONFIG.block_size] = load_block_structure(EXPERIMENT_CONFIG.block_structure_file);

%initialize RNG based on VPcode and date -> identical order on each run
reset_rng()

%old routines for generating block structure

%validation of block structure
% EXPERIMENT_CONFIG.block_count = 2*EXPERIMENT_CONFIG.seqsPerType / EXPERIMENT_CONFIG.blockSize;
% if EXPERIMENT_CONFIG.mixComplexitiesWithinBlocks && mod(2*EXPERIMENT_CONFIG.seqsPerType, EXPERIMENT_CONFIG.blockSize) ~= 0
%     error('block size is not divisor of total seq number')
% end
% if ~EXPERIMENT_CONFIG.mixComplexitiesWithinBlocks && mod(EXPERIMENT_CONFIG.seqsPerType, EXPERIMENT_CONFIG.blockSize) ~= 0
%     error('block size is not divisor of seq number per type')
% end
% 
% if ~EXPERIMENT_CONFIG.mixComplexitiesWithinBlocks && mod(EXPERIMENT_CONFIG.block_count, 2) ~= 0
%     error('need to have even block size if complexitites are not mixed')
% end
% complexSeqListFile = fullfile(PROJECT_SETUP.CONFIG_DIR, 'complex_seqs.txt');
% simpleSeqListFile = fullfile(PROJECT_SETUP.CONFIG_DIR, 'simple_seqs.txt');
% 
% EXPERIMENT_CONFIG.simpleSeqs = load_seq_list(simpleSeqListFile);
% if size(EXPERIMENT_CONFIG.simpleSeqs, 1) < EXPERIMENT_CONFIG.seqsPerType
%     error(['not enough simple scenes ', ...
%         num2str(size(EXPERIMENT_CONFIG.simpleSeqs, 1)), '/', num2str(EXPERIMENT_CONFIG.scenesPerType)])
% end
% EXPERIMENT_CONFIG.complexSeqs = load_seq_list(complexSeqListFile);
% if size(EXPERIMENT_CONFIG.complexSeqs, 1) < EXPERIMENT_CONFIG.seqsPerType
%     error(['not enough complex scenes ', ...
%         num2str(size(EXPERIMENT_CONFIG.complexSeqs, 1)), '/', num2str(EXPERIMENT_CONFIG.scenesPerType)])
% end
% 
% % build the actual structure
% EXPERIMENT_CONFIG.blockStructure = build_block_structure();

evalin('base', 'global EXPERIMENT_CONFIG');

EXPERIMENT_CONFIG %#ok<NOPRT>

%% utility functions

    function [blockStructure, blockCount, blockSize ] = load_block_structure( input_file )
        %LOAD_BLOCK_STRUCTURE Loads experiment block structure

        blockStructure = readtable(input_file,...
            'FileType', 'text',...
            'Delimiter', '\t',...    
            'ReadVariableNames', true);

        blockCount = size(unique(blockStructure.blockNo));
        blockSize = size(blockStructure.blockNo(blockStructure.blockNo == 0));

    end

    function seqList = load_seq_list(filePath)
        seqList = table2cell(readtable(filePath,...
        'Delimiter', '\t',...    
        'ReadVariableNames', false));
    end



end