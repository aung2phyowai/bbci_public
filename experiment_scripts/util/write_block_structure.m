function [  ] = write_block_structure( blocks, file )
%WRITE_BLOCK_STRUCTURE Writes the block structure to a file

% we need to collapse the third dimension (file name and fps)
% -> use tab as first-level and comma as second-level delimiter
collapsedBlock = cell(size(blocks, 1), size(blocks, 2));
for i = 1:size(blocks, 1)
   for j = 1:size(blocks, 2)
       collapsedBlock{i,j} = sprintf('%s,%d', blocks{i,j,1}, blocks{i,j,2});
   end
end

writetable(cell2table(collapsedBlock), file, 'WriteVariableNames', false, 'Delimiter', '\t')




end

