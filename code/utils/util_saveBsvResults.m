function [  ] = util_saveBsvResults(file_handle, metrics, parameters, meta, varargin )
%util_saveBsvResults Saves classification results in a log file in
%bar-separated format for the data explorer
%   file_handle: file handle to (opened) bsv file
%   metrics: struct with metric names as fieldnames and metric values as
%       corresponding field values
%   parameters: struct, each field consists of a parameter name and
%        the parameter's value
%   meta: struct, each field consists of a parameter name and
%        the parameter's value
%   varargin: pairs of group name as string and struct with corresponding
%        values

assert(isstruct(metrics))
assert(isstruct(parameters))
assert(isstruct(meta))


if length(intersect({'session', 'subject'}, fieldnames(parameters))) ~= 2
    warning('did not find session and subject information in parameters');
end

parser = inputParser;
parser.PartialMatching = false;
parser.KeepUnmatched = true;

%build a result id as identifier for this group of results
[~, hostname] = system('hostname');
default_rId = [strtrim(hostname) '-' datestr(now, 'yymmddHHMMSSFFF')];
if isfield(parameters, 'session')
   default_rId = [parameters.session '-' default_rId];
end

addParameter(parser, 'ResultId', default_rId)

parse(parser, varargin{:})
opts = parser.Results;


additional_groups =  parser.Unmatched;


if ~isempty(getenv('GIT_COMMIT'))
    gitRevision = getenv('GIT_COMMIT');
else
    %head to filter out "broken" characters
%     oldwd = pwd();
%     cd(PROJECT_SETUP.BASE_DIR);
    [~, gitRevision] = unix('TERM=ansi git log --no-color -1 --format="%H" | head');
    gitRevision = strtrim(gitRevision);
%     cd(oldwd);
end

% fprintf(outFp, '|%s|%s|%s|%s|\n', 'ResultID', 'Group', 'Key', 'Value');

rId = opts.ResultId;
fprintf(file_handle, '|%s|%s|%s|%s|\n', rId, 'meta', 'git_commit', gitRevision);
fprintf(file_handle, '|%s|%s|%s|%s|\n', rId, 'meta', 'datetime',  datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
for metaName = fieldnames(meta)'
    fprintf(file_handle, '|%s|%s|%s|%s|\n', rId, 'meta', metaName{1}, ...
        util_cell2name({meta.(metaName{1})}, '_', 'NormalizeForFilename', false));
end

for paramName = fieldnames(parameters)'
    fprintf(file_handle, '|%s|%s|%s|%s|\n', rId, 'parameter', paramName{1}, ...
        util_cell2name({parameters.(paramName{1})}, '_', 'NormalizeForFilename', false));
end

for metricName = fieldnames(metrics)'
    fprintf(file_handle, '|%s|%s|%s|%1.4f|\n', rId, 'metric', metricName{1}, ...
        metrics.(metricName{1}));
end

if isstruct(additional_groups)
    for group_name = fieldnames(additional_groups)'
        group_struct = additional_groups.(group_name{1});
        for fieldName = fieldnames(group_struct)'
            fprintf(file_handle, '|%s|%s|%s|%s|\n', rId, group_name{1}, fieldName{1}, ...
                util_cell2name({group_struct.(fieldName{1})}, '_', 'NormalizeForFilename', false));
        end
    end
end
