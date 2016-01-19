function [ mrk_labelled ] = vco_mrk_addEventLabels( mrk_base,  metadata)
%VCO_MRK_ADDEVENTLABELS adds event labels and durations to the event structure of the
%markers.
%   Adds the following fields to the mrk.event struct:
%    - vco_label: Label of the event
%    - vco_type: 'safe', 'uncertain', 'hazard' from label
%    - vco_duration: duration of event in ms floor(1000.0 * durations_in_frames / fps)

global PROJECT_SETUP

stimuli_marker_codes = struct2array(metadata.session.used_config.markers.stimuli);

seq_count = sum(mrk_base.event.desc == metadata.session.used_config.markers.technical.seq_start);

blocks = cell(metadata.vco_pilot_run.block_count, 1);

expected_seq_count = 0;

for k = 0:(metadata.vco_pilot_run.block_count - 1)
    block_sel = metadata.session.used_config.block_structure.blockNo == metadata.vco_pilot_run.start_block_no + k;
    blocks{k + 1} = table2cell(metadata.session.used_config.block_structure(block_sel, :));
    expected_seq_count = expected_seq_count + size(blocks{k + 1}, 1);
end

if expected_seq_count ~= seq_count
    error('recorded sequence start data does not match expected sequence count from metadata');
end

mrk_labelled = mrk_base;
mrk_labelled.event.event_name = cell(size(mrk_base.event.type));
mrk_labelled.event.seq_frame_no = zeros(size(mrk_base.event.desc));
mrk_labelled.event.event_class = cell(size(mrk_base.event.type));
mrk_labelled.event.event_frame_length = zeros(size(mrk_base.event.desc));
mrk_labelled.event.event_duration = zeros(size(mrk_base.event.desc));
mrk_labelled.event.marker_name = cell(size(mrk_base.event.type));

mrk_idx_last_seq_end = 0;
mrk_idx_seq_start = find(mrk_base.event.desc == metadata.session.used_config.markers.technical.seq_start);
mrk_idx_pause_start = find(mrk_base.event.desc == metadata.session.used_config.markers.technical.intra_block_pause_start);
mrk_idx_stimuli = find(ismember(mrk_base.event.desc, stimuli_marker_codes));
for k = 1:size(blocks, 1)
    cur_block = blocks{k};
    for l = 1:size(cur_block, 1)
        cur_seq_fps = cur_block{l, 3};
        cur_seq_subpath = strrep(cur_block{l, 2}, '/', filesep);
        seq_infos = load_seq_file_infos(cur_seq_subpath, metadata.session.used_config.markers);
        
        idx_seq_start = min(mrk_idx_seq_start(mrk_idx_seq_start > mrk_idx_last_seq_end));
        idx_pause_start = min(mrk_idx_pause_start(mrk_idx_pause_start > idx_seq_start));
        
        idx_stimulus_events = mrk_idx_stimuli(mrk_idx_stimuli > idx_seq_start...
            & mrk_idx_stimuli < idx_pause_start);
        
        if length(mrk_base.event.desc(idx_stimulus_events)) ~= length(seq_infos.marker_code)...
                || ~all(mrk_base.event.desc(idx_stimulus_events) == seq_infos.marker_code)
           error('recorded markers do not match the ones from seq file %s in block %d, sequence %d', ...
               cur_seq_subpath, k, l)
        end
        
        for n = 1:size(seq_infos, 1)
            event_idx = idx_stimulus_events(n);
            mrk_labelled.event.event_name{event_idx} = seq_infos.event_name{n};
            mrk_labelled.event.seq_frame_no(event_idx) = seq_infos.event_start_frame(n);
            mrk_labelled.event.event_class{event_idx} = seq_infos.event_type{n};
            mrk_labelled.event.event_frame_length(event_idx) = seq_infos.event_length(n);
            mrk_labelled.event.event_duration(event_idx) = floor(1000.0 * seq_infos.event_length(n) / cur_seq_fps);
            mrk_labelled.event.marker_name{event_idx} = seq_infos.marker_name{n};
       
        end
        
        mrk_idx_last_seq_end = idx_pause_start;
    end
end


    

end

