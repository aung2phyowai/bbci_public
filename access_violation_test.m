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

% recorder.Test();

recorder.Start();

for i = 1:1000000
  recorder.GatherData();
end


recorder.Stop();
