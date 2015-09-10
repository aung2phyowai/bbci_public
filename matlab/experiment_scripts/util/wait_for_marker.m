function [ ] = wait_for_marker( marker )
%WAIT_FOR_MARKER block until marker is received

global PROJECT_SETUP
socket = pnet('udpsocket', PROJECT_SETUP.UDP_MARKER_PORT);
lastObservedMarker = -1;

while lastObservedMarker ~= marker
    read_length=pnet(socket, 'readpacket', 4, 'noblock');
    if read_length > 0,
        data = pnet(socket, 'read', 4, 'char');
        lastObservedMarker= sscanf(data, '%u');  % -> parse string to number
    end
    pause(.05);
end
pnet(socket, 'close')
end