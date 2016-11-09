function name = util_cell2name(cell_input, delimiter, varargin)
%util_cell2name recursively converts a cell array to a string
%
% Parameters
%  cell_input              cell array to be converted
%  delimiter               char that is used to join the cell's elements
%
% Options
%   NormalizeForFilename   remove dots from the resulting string to use it as a filename (default true)


parser = inputParser;
parser.PartialMatching = false;

addParameter(parser, 'NormalizeForFilename', true)

parse(parser, varargin{:})
opts = parser.Results;

%ugly, but hey, it's matlab
any2str = @(x) evalc('disp(x)');
components = cell(size(cell_input));
for k=1:numel(cell_input)
    
    cur_comp = cell_input{k};
    if isnumeric(cur_comp)
        tmp_cell = cell(1, numel(cur_comp));
        %we transpose so that each row is adjacent in the string
        cur_comp = cur_comp';
        for l = 1:numel(cur_comp)
            %savepic doesn't handle points of floats well...
            if opts.NormalizeForFilename
                tmp_cell{l} = strrep(num2str(cur_comp(l)), '.', '_');
            else
                tmp_cell{l} = num2str(cur_comp(l));
            end
        end
        components{k} = strjoin(tmp_cell, '-');
        
    elseif iscell(cur_comp)
        components{k} = vco_src.analysis.util.cell2name({cur_comp{:}}, '-');
    elseif ischar(cur_comp)
        components{k} = cur_comp;
    elseif islogical(cur_comp)
        if cur_comp
            components{k} = 'true';
        else
            components{k} = 'false';
        end
    else
        components{k} = any2str(cur_comp);
    end
end

name = strjoin(strtrim(components), delimiter);
end