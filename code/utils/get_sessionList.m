function session_list = get_SessionList(fname)
% session_list = get_SessionList(fname)
% Returns in a cell array all the names of the subjects contained in a
% session list file (one subject per line)
% sebastian.castano@blbt.uni-freiburg.de
% 12. Jan 2015

fid = fopen(fname);
session_list={};
tline = fgetl(fid);
while ischar(tline)
    if ~isempty(tline)
        if tline(1) ~= '#'
            session_list{end+1}=strtrim(tline);
        end
    end
    tline = fgetl(fid);
end

fclose(fid);
end
