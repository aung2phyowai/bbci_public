function [  cnt, mrk_orig, hdr, metadata  ] = vco_load_raw_experiment(  experiment_name, experiment_run )
%vco_load_raw_experiment Summary of this function goes here
%   Detailed explanation goes here

global PROJECT_SETUP

loaded = false;
for cur_data_dir = PROJECT_SETUP.RECORDING_DIRS
    data_dir = fullfile(cell2mat(cur_data_dir), experiment_run);
    if exist(data_dir, 'dir') == 7
        fprintf(['loading data from ' data_dir '\n'])
        metadata_file = fullfile(data_dir, 'metadata.ini')
        if exist(metadata_file, 'file') ~= 2
            error(['Could not open metadata file ' metadata_file])
        end
        metadata = ini2struct(metadata_file);
        tmp = load(fullfile(data_dir, metadata.session.experiment_config_file), 'EXPERIMENT_CONFIG');
        metadata.session.used_config = tmp.EXPERIMENT_CONFIG;
        clear tmp
        
        
        if strcmp(experiment_name, 'vco_pilot_run')
            blocks_file_names = cell(1, metadata.vco_pilot_run.block_count);
            for k = 0:(metadata.vco_pilot_run.block_count - 1)
                block_no = metadata.vco_pilot_run.start_block_no + k;
                block_name = sprintf([metadata.vco_pilot_run.recording_prefix '%02d'], block_no);
                blocks_file_names{k + 1} = fullfile(data_dir, block_name);
            end
            
            [cnt, mrk_orig, hdr] = file_readBV(blocks_file_names);
            
            %read questionaires etc
            metadata.vco_pilot_run.complexity_ratings = readtable(...
                fullfile(data_dir, metadata.vco_pilot_run.complexity_ratings_file),...
                'FileType', 'text', 'Delimiter', '\t');
            
            metadata.vco_pilot_run.questionaire_answers = readtable(...
                fullfile(data_dir, metadata.vco_pilot_run.questionaire_answers_file),...
                'FileType', 'text', 'Delimiter', '\t');
            
            
            loaded = true;
        elseif strcmp(experiment_name, 'reaction_time')
            blocks_file_names = cell(1, metadata.reaction_time.block_count);
            for k = 0:(metadata.reaction_time.block_count - 1)
                block_name = sprintf([metadata.reaction_time.recording_prefix '%02d'], k);
                blocks_file_names{k + 1} = fullfile(data_dir, block_name);
            end
            
            [cnt, mrk_orig, hdr] = file_readBV(blocks_file_names);
            loaded = true;
        else
            error(['loading of experiment with name ' experiment_name ' not supported'])
        end
        
        break
    end
end

if ~loaded
    error(['could not load requested run ' experiment_run ' for experiment ' experiment_name])
end
end

