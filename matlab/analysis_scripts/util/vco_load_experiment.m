function [ cnt_pp, mrk_pp, hdr, metadata ] = vco_load_experiment( experiment_name, experiment_run, preprocessing_config, varargin )
%VCO_LOAD_SUBJECT Summary of this function goes here
%   Detailed explanation goes here

props= {'LoadFromMat'   true   'BOOL'};


opt= opt_proplistToStruct(varargin{:});
opt= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);


global BTB

% cellfun(@num2str, struct2cell(preprocessing_config), 'UniformOutput', false)
% string = evalc(['disp(preprocessing_config)'])

% al = java.util.ArrayList();
%undocumented function getByteStreamFromArray, but by far most simple solution
% al.add(getByteStreamFromArray(preprocessing_config))
ppc_string = java.util.Arrays.toString(getByteStreamFromArray(preprocessing_config));
config_hash = ppc_string.hashCode();
disp(['preprocessing with config ' num2str(config_hash)])

cache_file_name = fullfile(BTB.MatDir, strcat(experiment_name, '_', experiment_run, '_', num2str(config_hash)));

loaded = false;
if opt.LoadFromMat && exist([ cache_file_name '.mat'], 'file') == 2
    [cnt_pp, mrk_pp, mnt, hdr, saved_preprocessing_config,  metadata] = file_loadMatlab(cache_file_name, {'cnt','mrk','mnt', 'hdr', 'preprocessing_config', 'metadata'});
    if isequal(preprocessing_config, saved_preprocessing_config)
        loaded = true;
        disp('loaded preprocessed data from mat file')
    else
        warning('saved config did not match expected despite identical hash - recalculating from raw data')
    end
end

if ~loaded
    [  cnt, mrk_orig, hdr, metadata  ] = vco_load_raw_experiment(  experiment_name, experiment_run );
    
    if preprocessing_config.time_from_optic
        mrk_timed = vco_mrk_timeFromOptic(mrk_orig, metadata.session.used_config);
    else
        mrk_timed = mrk_orig;
    end

    %experiment-specific settings
    if strcmp(experiment_name, 'vco_pilot_run') 

        if preprocessing_config.add_event_labels
            mrk_timed = vco_mrk_addEventLabels(mrk_timed, metadata);
        end
    end
    
    %% Preprocessing
    
    mnt= mnt_setElectrodePositions(cnt.clab);
    [cnt_pp, mrk_pp] = vco_preprocess(cnt, mrk_timed, preprocessing_config);
    
    
    file_saveMatlab(cache_file_name, cnt_pp, mrk_pp, mnt,'Vars',{'hdr', 'preprocessing_config', 'metadata'});
    disp('calculated data from scratch, saved as mat file')
end