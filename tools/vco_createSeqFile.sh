#!/bin/bash
set -u
set -e
#should be executed in kitti base dir
#i.e., combined and seqs should be subdirs of `pwd`
seqName=$1
srcDir=$2
startNo=${3:-`find $srcDir/* | head -n 1 | sed -r 's%.*/([0-9]*).png%\1%'`}
endNo=${4:-`find $srcDir/* | tail -n 1 | sed -r 's%.*/([0-9]*).png%\1%'`}
performFades=${5:-false}

blendLength=10
imageFilePattern='%010d'
baseDir=`pwd`
seqDir="combined/${seqName}" #directory with image files/links for this sequence
seqFileDir="seqs" #directory with sequence files
seqFileName="seq_${seqName}.txt"

echo "linking images from $startNo to $endNo from $srcDir to $seqDir"
mkdir -p $seqDir
cd $seqDir
length=`echo "$endNo - $startNo" | bc`
for (( i=0; i < $length; i++ ))
do
    fileNo=`echo "${startNo} + ${i}" | bc`
    fileName=$(printf "${imageFilePattern}.png" $fileNo)
    #relative to original dir, but where in combined/seqDir, so two up
    ln -f -s "../../${srcDir}/${fileName}" .
done
echo "currently in directory `pwd`"
if [ "performFades" = true ] ; then
    echo "executing `dirname $0`/vco_fadeBlack.sh "in" $startNo $blendLength"
    `dirname $0`/vco_fadeBlack.sh "in" $startNo $blendLength
    fadeOutStartNo=`echo "$endNo - $blendLength" | bc`
    echo "executing `dirname $0`/vco_fadeBlack.sh "out" $fadeOutStartNo $blendLength"
    `dirname $0`/vco_fadeBlack.sh "out" $fadeOutStartNo $blendLength
fi
cd -
# entries in sequence file should be relative to seq fie path

cd $seqFileDir
#assume we are only one level down
find ../${seqDir}/* > $seqFileName
cd -
echo "created seq file ${seqFileDir}/${seqFileName}"
