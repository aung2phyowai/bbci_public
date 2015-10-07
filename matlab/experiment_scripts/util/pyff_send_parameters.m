function fbsettings = pyff_send_parameters(block_info, block_name)
%PYFF_SEND_PARAMETERS Builds feedback parameters based on
%EXPERIMENT_CONFIG and sends it
% block-info is a 1xNx2 cell array, with the second dimension corresponding
% to block size N and the accessing seq name or seq framerate

global PROJECT_SETUP
global EXPERIMENT_CONFIG

%convert to ``python'' list of tuples - slow implementation, but legible
seqNameFpsTupleList = '[';
for seqIdx = 1:size(block_info, 1)
    %convert to platform-specific path
    seqFileParts = strsplit(block_info.seqName{seqIdx}, '/');
    seqFile = fullfile(PROJECT_SETUP.BASE_DIR, seqFileParts{:});
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

fbsettings = struct;

fbsettings.param_logging_dir = EXPERIMENT_CONFIG.feedbackLogDir;
fbsettings.param_logging_prefix = EXPERIMENT_CONFIG.filePrefix;

fbsettings.use_optomarker = EXPERIMENT_CONFIG.feedback.use_optomarker;
fbsettings.screen_width = PROJECT_SETUP.SCREEN_SIZE(1);
fbsettings.screen_height = PROJECT_SETUP.SCREEN_SIZE(2);
fbsettings.screen_position_x = PROJECT_SETUP.SCREEN_POSITION(1);
fbsettings.screen_position_y = PROJECT_SETUP.SCREEN_POSITION(2);

fbsettings.param_block_seq_file_fps_list = seqNameFpsTupleList;
fbsettings.param_logging_prefix = [EXPERIMENT_CONFIG.filePrefix '_' block_name];
fbOpts = fieldnames(fbsettings);

fprintf('Sending feedback parameters:...\n')
fbsettings %#ok<NOPRT>
for optId = 1:length(fbOpts),
    pyff_sendUdp('interaction-signal', fbOpts{optId}, getfield(fbsettings, fbOpts{optId})); %#ok<GFLD>
end
fprintf('... Done!\n')

end

