function [] = validation_stats( bbci_data )
%VALIDATION_STATS Summary of this function goes here
%   Detailed explanation goes here

marker_stats(bbci_data.marker)

    function [] = marker_stats(marker)
        
        scatter(marker.time, marker.desc, 64, 'x')
        title('Observed markers')
        
        % calculate FPS based on 50-frame markers
        % 50 frames * 1000 ms/s / delta ms
        plot(diff(marker.time(marker.desc == 50)).^-1.*50.*1000)
        title('FPS based on 50-frame-markers')
    end
end

