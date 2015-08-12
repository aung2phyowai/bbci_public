function [] = validation_stats( bbci_data )
%VALIDATION_STATS Summary of this function goes here
%   Detailed explanation goes here

global PROJECT_SETUP


marker_stats(bbci_data.marker)

    function [] = marker_stats(marker)
        
        h = figure;
        scatter(marker.time, marker.desc, 64, 'x')
        title('Observed markers')
        uiwait(h)
        % calculate FPS based on 50-frame markers
        % 50 frames * 1000 ms/s / delta ms
        plot(diff(marker.time(marker.desc == PROJECT_SETUP.markers.sync_50_frames)).^-1.*50.*1000)
        title('FPS based on 50-frame-markers')
    end
end

