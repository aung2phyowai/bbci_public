% Demo of the LaTex Diary generator
clear;
close all

x = [0:0.01:2*pi];
y1 = sin(x);
y2 = sin(2*x);

% Cell arrays with the handles to figures to be saved and the struct
% containing the information of such figures (see resultsToTex
% documentation for a detailed description
figh = {};
figLatex = {};

mkdir('./report')
mkdir('./report/figures')

figLatex{end+1} = struct;
figLatex{end}.figname = 'figures/fig1';
figLatex{end}.caption = '''$y = sin(x)$''';
figLatex{end}.gwidth = 0.4;
figh{end+1} = figure();
plot(x,y1);


figLatex{end+1} = struct;
figLatex{end}.figname = 'figures/fig2';
figLatex{end}.caption = '''$y = sin(2x)$''';
figLatex{end}.gwidth = 0.4;
figh{end+1} = figure();
plot(x,y2);



dir_report = './report/';
extension = 'pdf';
for i = 1:numel(figh)
    savepic([dir_report figLatex{i}.figname],figh{i}, extension)
    figLatex{i}.figname = [figLatex{i}.figname '.' extension];
end

% Create header of the document
resultsToTex([dir_report 'test.tex'],'type','beginDoc')

% Insert figures
resultsToTex([dir_report 'test.tex'],'type','insertFig','figStruct',figLatex);

% Insert random text
resultsToTex([dir_report 'test.tex'],'type','insertRaw','rawContent','Hi, I am a random text $\\epsilon$')

% End file
resultsToTex([dir_report 'test.tex'],'type','endDoc')

system('bash batchTexCompilation.sh ./report output.pdf','-echo')