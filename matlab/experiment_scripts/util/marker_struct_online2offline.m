function [ offline_marker ] = marker_struct_online2offline( online_marker )
%MARKER_STRUCT_ONLINE2OFFLINE Converts the flat structure in data.marker
%(returned by bbci_apply) to structure as read from BV files
        offline_marker.event = struct;
        offline_marker.event.desc = online_marker.desc(~isnan(online_marker.time))';
        offline_marker.time = online_marker.time(~isnan(online_marker.time));

end

