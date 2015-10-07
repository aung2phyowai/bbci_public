function [] = validation_stats( bbci_data )
%VALIDATION_STATS Display marker statistics

global EXPERIMENT_CONFIG


marker_stats(bbci_data.marker)

    function [] = marker_stats(marker)
        
        h = figure;
        scatter(marker.time, marker.desc, 64, 'x')
        title('Observed markers')
        uiwait(h)
        
        seq_start_points_idxs = find(marker.desc == EXPERIMENT_CONFIG.markers.technical.seq_start);
        fps_by_seq = [];
        for seq_start_idx = seq_start_points_idxs
            seq_end_idx = find(marker.desc == EXPERIMENT_CONFIG.markers.technical.seq_end...
                & marker.time > marker.time(seq_start_idx), 1);
            seq_marker_time = marker.time(seq_start_idx:seq_end_idx);
            seq_marker_desc = marker.desc(seq_start_idx:seq_end_idx);
            fps_by_seq = [fps_by_seq, diff(seq_marker_time(seq_marker_desc == EXPERIMENT_CONFIG.markers.technical.sync_50_frames)).^-1.*50.*1000];
        end
        % calculate FPS based on 50-frame markers
        % 50 frames * 1000 ms/s / delta ms
        plot(fps_by_seq)
        title('FPS based on 50-frame-markers')
    end
end

