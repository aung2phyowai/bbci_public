function resultsToTex(fname,varargin)
% resultsToTex(fname,varargin)
% This function is a wrapper of the pytex_genMatlab.py script, which
% creates (or appends) content to a .tex file according to several
% templates.
% Input:
%   fname: String. Name of the .tex file in which the information is going
%   to be written
%   varargin: key-value pairs:
%       Available keys:
%       type: String.
%             - 'beginDoc' : Creates (or overwrites!) tex file and writes
%             standar header of a tex file. No value required. This is the
%             only type that overwrites existing file, the rest of types
%             append the content at the end
%             - 'endDoc' : appends \end{document} to the corresponding
%             document. No value required
%             - 'insertFig': Insert (sub)figures in the existing document.
%             The value corresponds to a cell array of structures with the
%             following fields: .
%                 .figname -> Directory and name with which the figure will
%                 be saved (RELATIVE TO THE .tex FILE FOLDER)
%                 .caption -> The caption you want the figure to have in the final document
%                 .gwidth -> Scalar from 0 to 1 determining the width of the figure within the page.
%             - 'insertRaw'-> Inserts raw tex code to the file. The value
%             corresponds to a string.
%
% Sebastian Castano. 20th Oct 2014
%
p = inputParser;

def_type = 'beginDoc';
def_figStruct = {}; % Only used when inserted figures
def_rawContent = ''; % Only used for raw tex input
def_figCaption = ''; % Only used for raw tex input

addParamValue(p,'type',def_type);
addParamValue(p,'figStruct',def_figStruct);
addParamValue(p,'rawContent', def_rawContent);
addParamValue(p,'figCaption', def_figCaption);

parse(p,varargin{:})
options = p.Results;


dir = strcat(fileparts(which('resultsToTex')));
base_command = ['python ' dir '/pytex_genMatlab.py --filename ' fname];
add_command = {};
switch options.type
    case 'beginDoc'
        add_command{end+1} = [' --type beginDoc --overwrite'];
    case 'endDoc'
        add_command{end+1} = [' --type endDoc'];
    case 'insertFig'
        
        add_command{end+1} = [' --type beginFigure'];
        if numel(options.figStruct) == 1
            options.figStruct = {options.figStruct};
        end
        for j= 1:numel(options.figStruct)
            add_command{end+1} = [' --type addSubfigure'];
            prop = fieldnames(options.figStruct{j});
            if numel(prop) > 0
                add_command{end} = [add_command{end} ' --properties'];
            end
            for i = 1:numel(prop)
                fieldval = getfield(options.figStruct{j}, prop{i});
                if isnumeric(fieldval)
                    fieldval = num2str(fieldval);
                end
                add_command{end} = [add_command{end} ' ' prop{i} ' ' fieldval];
            end
        end
        if ~isempty(options.figCaption)
            add_command{end+1} = [' --type addCaptionFigure --properties caption ',...
                options.figCaption];
        end
        add_command{end+1} = [' --type endFigure'];
        
    case 'insertRaw'
        add_command{end+1} = [' --type addRawText'];
        rcont = sprintf(['''' options.rawContent  '\\\\' '\n'  '''' ]);
        add_command{end} = [add_command{end} ' --properties text ' rcont ];
end

for i = 1:numel(add_command)
    system([base_command add_command{i}], '-echo');
end


