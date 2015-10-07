function [ blocks ] = build_block_structure()
%% deprecated, for reference only, use python script instead %%
%BUILD_BLOCK_STRUCTURE Creates a block structure for the experiment based
% on the configuration
%   Returns a list of tables, each element of the list constitutes a block
%   Each element (table) consists of sequence files and FPS
%   There is always the same number of simple and complex scenes as
%   specified in the experiment config

global EXPERIMENT_CONFIG

%reset RNG to create same block structure despite different previous calls
%to rand...
reset_rng()

complexSeqs = EXPERIMENT_CONFIG.complexSeqs;
simpleSeqs = EXPERIMENT_CONFIG.simpleSeqs;

if EXPERIMENT_CONFIG.sequences.randomize
    randComplexOrder = randperm(size(complexSeqs, 1));
    complexSeqs = complexSeqs(randComplexOrder, :);
    randSimpleOrder = randperm(size(simpleSeqs, 1));
    simpleSeqs = simpleSeqs(randSimpleOrder, :);
end

blocks = cell(EXPERIMENT_CONFIG.block_count, EXPERIMENT_CONFIG.blockSize, 2);

nextComplexSeqIdx = 1;
nextSimpleSeqIdx = 1;

for currentBlockNo = 1:EXPERIMENT_CONFIG.block_count
    currentBlock = cell(EXPERIMENT_CONFIG.blockSize, 2);
    
    %we alternate between simple and complex sequences,
    % either on block or on single sequence level
    if EXPERIMENT_CONFIG.mixComplexitiesWithinBlocks
        %decide for each sequence separately
        for currentSeqWithinBlock = 1:EXPERIMENT_CONFIG.blockSize
            if EXPERIMENT_CONFIG.sequences.randomize
                useSimple = rand > 0.5;
            else
                if mod(EXPERIMENT_CONFIG.blockSize, 2) == 0
                    useSimple = mod(currentSeqWithinBlock, 2) == 0;
                else
                    useSimple = mod(currentBlockNo, 2) ~= mod(currentSeqWithinBlock, 2);
                end
            end
            % if we only have one type left, use that
            useSimple = (useSimple && nextSimpleSeqIdx <= EXPERIMENT_CONFIG.seqsPerType)...
                || nextComplexSeqIdx > EXPERIMENT_CONFIG.seqsPerType;
            if useSimple && nextSimpleSeqIdx > EXPERIMENT_CONFIG.seqsPerType
                error('neither enough simple nor enough complex sequences')
            end
            if useSimple
                currentBlock(currentSeqWithinBlock,:) = simpleSeqs(nextSimpleSeqIdx, :);
                nextSimpleSeqIdx = nextSimpleSeqIdx + 1;
            else
                currentBlock(currentSeqWithinBlock,:) = complexSeqs(nextComplexSeqIdx, :);
                nextComplexSeqIdx = nextComplexSeqIdx + 1;
            end
        end
        
        
    else % complete block has identical type
        if EXPERIMENT_CONFIG.sequences.randomize
            enoughSimpleLeft = (nextSimpleSeqIdx + EXPERIMENT_CONFIG.blockSize - 1) <= EXPERIMENT_CONFIG.seqsPerType;
            enoughComplexLeft = (nextComplexSeqIdx + EXPERIMENT_CONFIG.blockSize - 1) <= EXPERIMENT_CONFIG.seqsPerType;
            
            useSimple = (rand > 0.5 && enoughSimpleLeft)...
                || (~enoughComplexLeft);
        else
            useSimple = mod(currentBlockNo, 2) ~= 0;
        end
        if useSimple
            lastIndexForBlock = nextSimpleSeqIdx + EXPERIMENT_CONFIG.blockSize - 1;
            if lastIndexForBlock > EXPERIMENT_CONFIG.seqsPerType
                error('not enough simple sequences')
            end
            currentBlock = simpleSeqs(nextSimpleSeqIdx:lastIndexForBlock, :);
            nextSimpleSeqIdx = lastIndexForBlock + 1;
        else
            lastIndexForBlock = nextComplexSeqIdx + EXPERIMENT_CONFIG.blockSize - 1;
            if lastIndexForBlock > EXPERIMENT_CONFIG.seqsPerType
                error('not enough complex sequences')
            end
            currentBlock = complexSeqs(nextComplexSeqIdx:lastIndexForBlock, :);
            nextComplexSeqIdx = lastIndexForBlock + 1;
        end
    end
    
    
    blocks(currentBlockNo,:,:) = currentBlock;
end