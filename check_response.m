function result = check_response(code)

result = 0;

switch code
    case 1
        result = 1;
    case 104
        display('Could not establish connection. Check if Eye Tracker is running');
    case 105
        display('Could not establish connection. Check the communication Ports');
    case 123
        display('Could not establish connection. Another Process is blocking the communication Ports');
    case 200
        display('Could not establish connection. Check if Eye Tracker is installed and running');
    otherwise
        display('Could not establish connection. Check manual for error code');
        display(code)
end

end

