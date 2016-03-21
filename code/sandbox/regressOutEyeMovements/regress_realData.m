% Supervised cleaning of eye artifacts (demo of the
% proc_regressOutComponent)
%
% Sebastian Castano
% 13th Nov. 2014
close all; clc


set_localpaths();


%% Load data
VP = 'VPpas_14_09_12';
runs = 1;
fname = [VP '/posner_pilot_run'];

files2load = {};
for i = runs
    files2load{end+1} = [fname num2str(i) '_'];
end
[cnt vmrk ~] = file_readBV(files2load);
[hdr] = file_readBVheader(files2load{1});


%% Extract time series to regress out of the EEG (here, eye artifacts
EoG_proj = procutil_biplist2projection(cnt.clab,{{'F9' 'F10' 'EOGh'}, {'EOGvu' 'Fp2' 'EOGv'}});

%% Clean data
s = zeros(size(cnt.x,1),numel(EoG_proj));
cnt_orig = cnt;
for i = 1:size(s,2)
    out = proc_linearDerivation(cnt, EoG_proj(i).filter);
    s(:,i) = out.x;    
    [cnt.x, A, s_hat] = proc_regressOutComponent(cnt.x, s(:,i));
end

%% Results
figure
subplot(2,1,1)
plot(cnt_orig.x)
title('original')
subplot(2,1,2)
plot(cnt.x);
title('Cleaned')