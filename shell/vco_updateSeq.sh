#!/bin/bash
#example call
# vco_updateSeq.sh c09_1-weiherfelda-mod1 combined/c09_1-weiherfelda/ modified/c09_1-weiherfelda-0050-motherChild/renamed/
set -ue
targetSeqName=$1
baseSeqDir=$2
updateFramesDir=$3
#which frames should be read from $updateFramesDir
updateStartFrameNo=${4:-`find ${updateFramesDir%/}/* | head -n 1 | sed -r 's%.*/([0-9]*).png%\1%'`}
updateEndFrameNo=${5:-`find ${updateFramesDir%/}/* | tail -n 1 | sed -r 's%.*/([0-9]*).png%\1%'`}
#which frames should be replaced in the target sequence
targetStartFrameNo=${6:-$updateStartFrameNo}
targetEndFrameNo=${7:-$updateEndFrameNo}

seqFileDir="seqs" #directory with sequence files
targetSeqDir="combined/${targetSeqName}" #directory with images (/links) for the target sequence
imageFilePattern='%010d'
targetSeqFileName="seq_${targetSeqName}.txt"
modifiedEventMarker="generic_stimulus"

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
find ../${targetSeqDir}/* > ${targetSeqFileName}.tmp
#use markers from base file
baseSeqFile=seq_`basename ${baseSeqDir}`.txt
if [ -e $baseSeqFile ] ;
then
    echo "base seq file ${baseSeqFile} exists, copying markers"
    #grep might fail, so change flags for next command
    set +e
    linesWithMarkers=$(grep -P -o '[^/]*\t.*$' ${baseSeqFile})
    grepStatus=$?
    set -e
    if [ $grepStatus == 0 ]; then
	echo " found the following markers"
	while read -r curMarkerFragment; do
	    curFileName=$(echo "$curMarkerFragment" | sed "s/^\([^\t]*\)\t.*$/\\1/")
	    echo "   replacing $curFileName with $curMarkerFragment"
	    sed -i "s/${curFileName}/${curMarkerFragment}/" ${targetSeqFileName}.tmp
	done <<< "$linesWithMarkers"
    else
	echo " no markers found"
    fi
    
fi
#add marker to line
#current limitation: will not work if the line has already markers
firstUpdatedFileName=$(printf "${imageFilePattern}.png" $(echo $targetStartFrameNo + 0 | bc)) 
sed s/\\\(${firstUpdatedFileName}\\\)$/\\1\\t${modifiedEventMarker}/ ${targetSeqFileName}.tmp > ${targetSeqFileName}
rm ${targetSeqFileName}.tmp
cd -
echo "created seq file ${seqFileDir}/${targetSeqFileName}"
