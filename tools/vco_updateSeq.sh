#!/bin/bash
set -ue
targetSeqName=$1
baseSeqDir=$2
updateFramesDir=$3
#which frames should be read from $updateFramesDir
updateStartFrameNo=${4:-`find ${updateFramesDir}/* | head -n 1 | sed -r 's%.*/([0-9]*).png%\1%'`}
updateEndFrameNo=${5:-`find ${updateFramesDir}/* | tail -n 1 | sed -r 's%.*/([0-9]*).png%\1%'`}
#which frames should be replaced in the target sequence
targetStartFrameNo=${6:-$updateStartFrameNo}
targetEndFrameNo=${7:-$updateEndFrameNo}

seqFileDir="seqs" #directory with sequence files
targetSeqDir="combined/${targetSeqName}" #directory with images (/links) for the target sequence
imageFilePattern='%010d'
targetSeqFileName="seq_${targetSeqName}.txt"

mkdir -p $targetSeqDir
echo "cp -rv "${baseSeqDir%/}/*" ${targetSeqDir%/}/"
cp -rv ${baseSeqDir%/}/* $targetSeqDir
cd $targetSeqDir

updateFrameCount=`echo "${updateEndFrameNo} - ${updateStartFrameNo}" | bc`
for (( i=0; i < $updateFrameCount; i++ ))
do
    updateFileNo=`echo "${updateStartFrameNo} + ${i}" | bc`
    updateFileName=$(printf "${imageFilePattern}.png" $updateFileNo)
    targetFileNo=`echo "${targetStartFrameNo} + ${i}" | bc`
    targetFileName=$(printf "${imageFilePattern}.png" $targetFileNo)
    echo " ln -f -s ../../${updateFramesDir}/${updateFileName} ${targetFileName}"
    ln -f -s "../../${updateFramesDir}/${updateFileName}" "${targetFileName}"
done

#TODO do we need to fade-in/fade-out again
cd -
cd $seqFileDir

#assume we are only one level down
find ../${targetSeqDir}/* > $targetSeqFileName
cd -
echo "created seq file ${seqFileDir}/${targetSeqFileName}"
