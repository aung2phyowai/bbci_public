function fbsettings = pyff_send_parameters(block_info, block_name)
%PYFF_SEND_PARAMETERS Builds feedback parameters based on
%EXPERIMENT_CONFIG and sends it
% block-info is a 1xNx2 cell array, with the second dimension corresponding
% to block size N and the accessing seq name or seq framerate

global PROJECT_SETUP
global EXPERIMENT_CONFIG

if ~exist(EXPERIMENT_CONFIG.feedbackLogDir, 'dir')
    mkdir(EXPERIMENT_CONFIG.feedbackLogDir)
end


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

fbsettings = struct;
fbsettings.optomarker_enabled = EXPERIMENT_CONFIG.feedback.use_optomarker;
fbsettings.screen_width = PROJECT_SETUP.SCREEN_SIZE(1);
fbsettings.screen_height = PROJECT_SETUP.SCREEN_SIZE(2);
fbsettings.screen_position_x = PROJECT_SETUP.SCREEN_POSITION(1);
fbsettings.screen_position_y = PROJECT_SETUP.SCREEN_POSITION(2);
fbsettings.overlay_duration = EXPERIMENT_CONFIG.feedback.overlay_duration;
fbsettings.display_debug_information = EXPERIMENT_CONFIG.feedback.show_debug_infos;
fbsettings.playback_delay = EXPERIMENT_CONFIG.feedback.playback_delay;


fbsettings.log_dir = EXPERIMENT_CONFIG.feedbackLogDir;
fbsettings.log_prefix = EXPERIMENT_CONFIG.filePrefix;
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

