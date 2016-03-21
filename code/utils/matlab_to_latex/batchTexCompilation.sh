#!/bin/bash
# This script
# input arguments
# First: directory where the tex files are
# Second: name of the output document.
# 
# Usage:
# bash batchTexCompilation dir_to_files output.pdf
cd  $1 
rm *.pdf
n_files=0
for line in *.tex; do
	pdflatex -synctex=1 -interaction=nonstopmode $line
	let n_files=n_files+1
done
echo $n_files
if [ $n_files -gt 1 ];
then pdfunite *.pdf merged_files.tmp
fi
if [ $n_files -eq 1 ];
then mv *.pdf merged_files.tmp
fi
rm *.pdf *.aux *.log  *.synctex.gz

mv merged_files.tmp $2
