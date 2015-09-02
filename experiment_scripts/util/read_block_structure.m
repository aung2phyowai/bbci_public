function [ parsed_blocks ] = read_block_structure( file )
%READ_BLOCK_STRUCTURE Reads a block structure serialized by
%write_block_structure back into Matlab

collapsed_blocks = table2cell(readtable(file, 'ReadVariableNames', false, 'Delimiter', '\t'));

%anything but elegant...
parsed_blocks = cell(size(collapsed_blocks, 1), size(collapsed_blocks, 2), 2);
for i = 1:size(collapsed_blocks, 1)
   for j = 1:size(collapsed_blocks, 2)
       split_cell = textscan(collapsed_blocks{i,j}, '%s %d', 'Delimiter', ',');
       
       parsed_blocks{i,j, 1} = cell2mat(split_cell{1});
       parsed_blocks{i,j, 2} = split_cell{2};
   end
end
end

