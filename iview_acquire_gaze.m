function varargout= iview_acquire_gaze(varargin)

    global ACQ_MARKER
    persistent recorder
    persistent sock
    
    output = {};

    if isequal(varargin{1}, 'persistent_init'),   
        if isempty(recorder)
            display('start recorder')
            file_path = mfilename('fullpath');
            idx = max(strfind(file_path, '\'));
            dir_path = file_path(1:idx);
            NET.addAssembly([dir_path '\bin\iViewClient.dll']);

            params = iViewClient.RecorderParameters();
            params.SendAddress = '192.168.1.2';
            params.SendPort = 4444;
            params.ReceiveAddress = '192.168.1.1';
            params.ReceivePort = 5555;
            recorder = iViewClient.Recorder(params);
        end
        if isempty(sock)
            display('persistent init')
            sock = pnet('udpsocket', 12344);
        end
    elseif isequal(varargin{1}, 'persistent_close'),
        %pnet(sock, 'close');
        %sock = [];
        recorder.Stop();
        recorder = [];
    elseif isequal(varargin{1}, 'init'),
        state= opt_proplistToStruct(varargin{2:end});
        init(state);
    elseif isequal(varargin{1}, 'close'),
%         if length(varargin)>1,
%             state= varargin{2};
%             close(state);
%         end
        recorder.Stop();
        return
    elseif length(varargin)~=1,
    	error('Except for INIT/CLOSE case, only one input argument expected');
    else
    	if ~isstruct(varargin{1}),
            error('First input argument must be ''init'', ''close'', or a struct');
        end
        state = varargin{1};
        get_data(state);
    end
    varargout= output(1:nargout);

    function init(state)
        default_clab= {'iView_left_x', 'iView_left_y', 'iView_left_diam', ...
                       'iView_right_x', 'iView_right_y', 'iView_right_diam'};
        props= {'fs'           1000           '!DOUBLE[1]'
               'clab'          default_clab   'CELL{CHAR}'
               'blocksize'     40             '!DOUBLE[1]'
               'realtime'      1              '!DOUBLE[1]'
             };
        state= opt_setDefaults(state, props, 1);
        state.nChannels= length(state.clab);
        state.blocksize_sa= ceil(state.blocksize*state.fs/1000);
        state.blocksize= state.blocksize_sa*1000/state.fs;
        state.nsamples= 0;
        if state.realtime==0,
            state.realtime= inf;
        end
        state.start_time= tic;
        
        state.active = false;
        recorder.Start();
        
        output= {state};
    end

%     function close()
%         recorder.Stop();
%         recorder = [];
%         display('closed')
%     end

    function get_data(state)
        time_running= toc(state.start_time);
        if time_running < state.nsamples/state.fs/state.realtime,
            output= {[], [], [], state};
            varargout= output(1:nargout);
            return;
        end
        
        if ~state.active
          pocketSize = pnet(sock, 'readpacket', 'noblock');
          if pocketSize > 0
            packet = pnet(sock, 'read', 'noblock');
            if(str2double(packet) == 100),
                state.active = true;
                display('Marker 100 captured, iView activated!');
            end
          end
        end
        
        if state.active,
            cntx = get_iview_data(state);
            state.nsamples= state.nsamples + size(cntx, 1);
        else
            recorder.GatherData();
            cntx = [];
        end
        

        output= {cntx, [], [], state};
    end

    function cntx= get_iview_data(state)
        state= varargin{1};
        
        gaze_data = double(recorder.GatherData());
        
        timestamps = int64(gaze_data(:, 1) / 1000);        
        timestamp_delta = timestamps(2:end) - timestamps(1:end-1);
        
        if size(timestamp_delta) ~= 0
            timestamp_indices = 1:size(timestamp_delta);
            resampled_gaze_data = arrayfun(@(index, delta) repmat(gaze_data(index, 2:end), delta, 1), ...
                                           timestamp_indices, timestamp_delta.', 'UniformOutput', false).';
            cntx = cell2mat(resampled_gaze_data);
        else 
            cntx = [];
        end
    end

end