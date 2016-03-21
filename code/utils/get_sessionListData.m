function [ status ] = get_sessionListData( session_list, user, ip, varargin)
% [ status ] = get_sessionListData( session_list, user, ip )
% Checks if the data of a given session list is stored in the cluster,
% and if not, it copies it from the local machine and stores it in the
% DataDir set in the BWUniCluster for the bbci toolbox
%
% Input
%       session_list: name of the text file with the name of the VPs
%       user: string containing the username in the local machine
%       ip: string. IP address of the local machine
%
% Sebastian Castano
% jscastanoc@gmail.com
% 2015

options = propertylist2struct(varargin{:});
options = set_defaults(options,...
    'LocalDir',fullfile('/mnt','fs_bsdlab','data','bbciRaw')); % dir to data in the local machine

global BTB

status = 0;
VPs = get_sessionList(session_list);
for idx_vp = 1:numel(VPs)
    vp_folder = fullfile(BTB.DataDir,VPs{idx_vp});
    s_folder = 0;
    if exist(vp_folder)
        dir_prop = dir(vp_folder);
        for idx_f = 1:numel(dir_prop)
            s_folder = s_folder + dir_prop(idx_f).bytes;
        end
    end
    if s_folder ~=0
        fprintf('data for %s already exists here, skipping...\n',VPs{idx_vp})   
    else
        remotedir = fullfile(options.LocalDir,VPs{idx_vp},'*');
        localdir = fullfile(BTB.DataDir,VPs{idx_vp});
        mkdir(localdir);
        command = ['scp',' -r  ',user,'@',ip,':',remotedir,' ',localdir];
%         command = ['lftp sftp://user,'@',ip,':',remotedir,' ',localdir];
        system(command)
    end
end

