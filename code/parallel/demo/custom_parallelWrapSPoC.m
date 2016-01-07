function custom_parallelWrapSPoC(VP, datadir, pardir, resultsdir)
% custom_parallelWrapSPoC(argdir, argname)
%
% Input:
%       parname: string or cell array. Full path to the location of the parameters
%               If cell array, the files are processed in the same job
%       datadir: string. Path to where the preprocessed data is saved. See
%               demo_SPoCGridPrepared in the Parallel demos to see how the data
%               should be preprocessed.
%       pardir: string. Path to where the parameter parname is saved
%       resultsdir: string. Path to where the custom_SPoC function is
%               saving the results
%
% The parameter file parname is cell array with the following pairs key-value:
%         VP:       string. Name of the subject (bsdlab VP naming)
%         ival:     1x2 vector. Time interval to analysis with respect to the mrk
%         fband:    1x2 vector. Frequency band to analyse
%         mapf:     function handle. Mapping of the target variable
%
% The data file of the subject VP contains, as separate variables:
%         cnt_eeg:  struct. Standard cnt structure with the EEG channels
%         mrk:      struct. Standard marker structure what marks the stimulus onset
%                   at t=0, this time point is the reference of the ival variable defined
%                   above.
%         z:        1xNtrials vector. Double vector with the target variable for
%                   each trial.
%         rtrials:  1xNrejected vector. Vector encoding the rejected trials
%
% sebastian.castano@blbt.uni.freiburg.de
% 16. Dec. 2014


fdata = fullfile(datadir,VP);
load(fdata,'cnt_eeg','mrk','z','rtrials');

parameters = strsplit(ls(pardir));
parameters = parameters(~cellfun('isempty',parameters));
% try
%     parpool;
% catch exception
%     warning('parpool threw the following exception!')
%     exception
% end

args_all = {};
for j = 1:numel(parameters)
    fpar = fullfile(pardir,parameters{j})
    load(fpar,'args','opts');
    args_all{end+1} = args;
end

cnt_eeg = cnt_eeg;
mrk = mrk;
z = z;
rtrials = rtrials;
parfor j = 1:numel(parameters)
        args = args_all{j};
    
        % Parse args
        p = inputParser;
        addParameter(p,'ival',[]);
        addParameter(p,'fband',[]);
        addParameter(p,'mapf',[]);
        parse(p,args{:});
        param = p.Results;
    
        % Load parameters
        save_name = fullfile(resultsdir,VP);
        if ~exist(save_name)
            mkdir(save_name);
        end
        save_name = fullfile(save_name,parameters{j});
        arg_SPoC = {cnt_eeg, mrk, z, param.mapf, param.ival, param.fband, save_name, opts{:}};
        custom_SPoC(arg_SPoC{:});
    
    %     createTask(job, @custom_SPoC, 0, arg_SPoC);
    %     if ~mod(j,NinstMax) || j == numel(parameters)
    %         submit(job);
    %         wait(job,'finished');
    %         errmsgs = get(job.Tasks, {'ErrorMessage'});
    %         nonempty = ~cellfun(@isempty, errmsgs);
    %         celldisp(errmsgs(nonempty));
    %         destroy(job);
    %         job = createJob(sched);
    %     end
end

end
