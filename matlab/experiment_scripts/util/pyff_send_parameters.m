function fbsettings = pyff_send_parameters(block_info, block_name)
%PYFF_SEND_PARAMETERS Builds feedback parameters based on
%EXPERIMENT_CONFIG and sends it
% block-info is a 1xNx2 cell array, with the second dimension corresponding
% to block size N and the accessing seq name or seq framerate

global PROJECT_SETUP
global EXPERIMENT_CONFIG

pyff_send_base_parameters()


%convert to ``python'' list of tuples - slow implementation, but legible
seqNameFpsTupleList = '[';
for seqIdx = 1:size(block_info, 1)
    %convert to platform-specific path
    seqFileParts = strsplit(block_info.seqName{seqIdx}, '/');
    seqFile = fullfile(PROJECT_SETUP.VCO_DATA_DIR, seqFileParts{:});
    if exist(seqFile, 'file') == 0
        % sequence file not accessible, so we don't bother starting the feedback
        fprintf(['Cannot access ', seqFile, ', aborting!\n'])
        break;
    end
    nameFpsTuple = sprintf('("%s", %d)', seqFile, block_info.FPS(seqIdx));
    if seqIdx ~= 1
        nameFpsTuple = [','  nameFpsTuple]; %#ok<AGROW>
    end
    seqNameFpsTupleList = [seqNameFpsTupleList, nameFpsTuple]; %#ok<AGROW>
end
seqNameFpsTupleList = [seqNameFpsTupleList, ']'];


fbsettings = EXPERIMENT_CONFIG.fb.img_seq;


fbsettings.log_prefix_block = [EXPERIMENT_CONFIG.filePrefix '_' block_name];

fbsettings.next_block_info = seqNameFpsTupleList;


fbOpts = fieldnames(fbsettings);

fprintf('Sending feedback parameters:...\n')
fbsettings %#ok<NOPRT>
for optId = 1:length(fbOpts),
    pyff_sendUdp('interaction-signal', fbOpts{optId}, getfield(fbsettings, fbOpts{optId})); %#ok<GFLD>
    pause(0.1)
end
fprintf('... Done!\n')
end

