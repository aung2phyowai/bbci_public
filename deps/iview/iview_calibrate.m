function iview_calibrate(varargin)

init_props= {'SendAddress'       '192.168.1.2'       '!CHAR'
            'SendPort'          4444                '!INT[1]'
            'ReceiveAddress'    '192.168.1.1'       '!CHAR'
            'ReceivePort'       5555                '!INT[1]'
            'SaveAccuracy'      false               'BOOL[1]'
            'LogFile'           ''                  'CHAR'
            'LogLabel'          ''                  'CHAR'
    };
calib_opts = opt_proplistToStruct(varargin{1:end});
calib_params = opt_setDefaults(calib_opts, init_props, 1);

includename = 'iViewXAPI.h';
dllname = 'iViewXAPI64.dll';
libraryname = 'iViewXAPI64';

[notfound, warning] = loadlibrary(dllname, includename);

[pSystemInfoData, pSampleData, pEventData, pAccuracyData, CalibrationData] = InitiViewXAPI();

CalibrationData.method = int32(5);
CalibrationData.visualization = int32(1);
CalibrationData.displayDevice = int32(1);
CalibrationData.speed = int32(0);
CalibrationData.autoAccept = int32(1);
CalibrationData.foregroundBrightness = int32(239);
CalibrationData.backgroundBrightness = int32(20);
CalibrationData.targetShape = int32(3);
CalibrationData.targetSize = int32(30);
CalibrationData.targetFilename = int8('');
pCalibrationData = libpointer('CalibrationStruct', CalibrationData);

disp('Connect to iViewX (eyetracking-server)')
res = calllib(libraryname, 'iV_Connect', calib_params.SendAddress, int32(calib_params.SendPort),...
    calib_params.ReceiveAddress, int32(calib_params.ReceivePort));
connected = check_response(res);

if connected
    disp('Calibrate iView X (eyetracking-server)')
    
    res = calllib(libraryname, 'iV_SetupCalibration', pCalibrationData);
    check_response(res);
    
    res = calllib(libraryname, 'iV_Calibrate');
    check_response(res);


    disp('Validate Calibration')
    
    res = calllib(libraryname, 'iV_Validate');
    check_response(res);


    disp('Show Accuracy')
    
    res = calllib(libraryname, 'iV_GetAccuracy', pAccuracyData, int32(0));
    check_response(res);
    
    accuracy_struct = get(pAccuracyData, 'Value')
    
    if calib_params.SaveAccuracy
        
        log_table = struct2table(accuracy_struct);
        log_table.time = datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF');
        log_table.label = calib_params.LogLabel;
        if exist(calib_params.LogFile, 'file') == 2
           old_log_table = readtable(calib_params.LogFile, 'FileType', 'text', 'Delimiter', '\t');
           log_table = union(old_log_table, log_table);
           log_table = sortrows(log_table, 'time');
        else
        end
        writetable(log_table, calib_params.LogFile, 'FileType', 'text', 'Delimiter', '\t');
    end
end

disp('Disconnect from iViewX')
res = calllib(libraryname, 'iV_Disconnect');
check_response(res);

pause(1);
clearvars -except libraryname

unloadlibrary(libraryname);

end

