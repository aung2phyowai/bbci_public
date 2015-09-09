#!/bin/bash
# copies partial data folders for selected sequence files
#  links are replaced with the actual file content
#  should be executed from kitti main folder
# parameters:
#  $1    sequence file
#  $2    base target directory
set -ue
seqFile="$1"
targetDir="$2"
seqDir="${targetDir}/seqs"
srcCombinedDir="./combined"
targetCombinedDir="${targetDir}/combined"
if [ ! -d "$targetDir" ]; then
    echo "make sure the target directory exists"
    exit 1
fi
if [ ! -f "$seqFile" ]; then
    echo "sequence file does not exist"
    exit 2
fi
if [ ! -d "$srcCombinedDir" ]; then
    echo "cannot find combined subdirectory in current folder"
    exit 3
fi
echo "copying all image data referenced in sequence file $seqFile"
if [ ! -d "$seqDir" ]; then
    mkdir -pv "$seqDir"
fi
if [ ! -d "$targetCombinedDir" ]; then
    mkdir -pv "$targetCombinedDir"
fi
cp -v "$1" "$seqDir"
#copy all combined directories, so we need to find them first
dirsToSync=`cat ${seqFile} | sed "s/^.*combined\\///" | sed "s/\\/[0-9]*\\.png.*//" | grep -v "#" | sort -u`
echo "syncing the following directories of combined"
echo $dirsToSync
#exit 0
while read -r curDir; do
    #rsync, replacing links with actual file
    rsync -azh --copy-links --copy-dirlinks --info=PROGRESS2 "${srcCombinedDir}/${curDir}" "${targetCombinedDir}"
done <<< "$dirsToSync"
