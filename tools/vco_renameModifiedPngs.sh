#!/bin/bash
# renames to base number, expects target number of first as base
# should be executed within folder
set -ue
mkdir renamed
for file in *.png
do
    fileIncr=`echo ${file} | sed s/^.*_// | sed  s/\\.png//`
    fileNo=`echo $1 + ${fileIncr} - 1 | bc`
    fileName=$(printf '%010d.png' $fileNo)
    echo "$file -> $fileName"
    cp $file renamed/$fileName
done
