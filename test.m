pnet('closeall');

socket = pnet('udpsocket', 12344);

while true
    pause(1);
    size = pnet(socket, 'readpacket', 10, 'noblock');
    display(size);
    if size > 0
        data = pnet(socket, 'read');
        display(data);
        break
    end
end

pnet(socket, 'close');
