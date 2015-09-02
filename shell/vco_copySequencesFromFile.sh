#!/bin/bash
# copy sequences from file
# each line of file represents a sequence file name
# should be executed from the kitti directory
set -ue
seqNameFile="$1"
targetDir="$2"
seqDir="./seqs"
seqFileNames=`cat $seqNameFile | sed "s/\\t.*$//"`
while read -r curSeqFileName; do
    if [ -f "${seqDir}/${curSeqFileName}" ]; then
	vco_copySequence.sh "${seqDir}/${curSeqFileName}" "${targetDir}"
    else
	echo "cannot find '$seqDir/$curSeqFileName'  - ignoring"
    fi
done <<< "$seqFileNames"
