#!/bin/bash
#example call
# vco_updateSeq.sh c09_1-weiherfelda-mod1 safe-c09_1-1 combined/c09_1-weiherfelda/ modified/c09_1-weiherfelda-0050-motherChild/renamed/
set -ue
targetSeqName=$1
updateLabel=$2 #label with type-prefix, e.g., safe-seqxy-1, hazard-seqxy-2
baseSeqDir=$3
updateFramesDir=$4
modifiedEventMarker=${5:-"generic_stimulus"}
#which frames should be read from $updateFramesDir
updateStartFrameNo=${6:-`find ${updateFramesDir%/}/* | head -n 1 | sed -r 's%.*/([0-9]*).png%\1%'`}
updateEndFrameNo=${7:-`find ${updateFramesDir%/}/* | tail -n 1 | sed -r 's%.*/([0-9]*).png%\1%'`}
#which frames should be replaced in the target sequence
targetStartFrameNo=${8:-$updateStartFrameNo}
targetEndFrameNo=${9:-$updateEndFrameNo}


seqFileDir="../seqs" #directory with sequence files
targetSeqDir=`realpath "combined/${targetSeqName}"` #directory with images (/links) for the target sequence
imageFilePattern='%010d'
targetSeqFileName=`realpath "${seqFileDir}/seq_${targetSeqName}.txt"`
eventName="E-${updateLabel}"


#check that we're in the base directory
if [ ! -d "combined" ]; then
    echo "cannot find combined subdirectory in current folder"
    exit 2
fi

if [ ! -d "${seqFileDir}" ]; then
    echo "cannot find $seqFileDir in current folder"
    exit 3
fi

# copy the base version
mkdir -p $targetSeqDir
echo "cp -rv "${baseSeqDir%/}/*" ${targetSeqDir%/}/"
cp -rv ${baseSeqDir%/}/* $targetSeqDir


## create seq file and initialize with markers

#assume we are only one level down
find ${targetSeqDir}/* > ${targetSeqFileName}.tmp
#use markers from base file
baseSeqFile="${seqFileDir}/seq_`basename ${baseSeqDir}`.txt"
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

## update files and seq file
cd $targetSeqDir
updateFrameCount=`echo "${updateEndFrameNo} - ${updateStartFrameNo} + 1" | bc`
for (( i=0; i < $updateFrameCount; i++ ))
do
    updateFileNo=`echo "${updateStartFrameNo} + ${i}" | bc`
    updateFileName=$(printf "${imageFilePattern}.png" $updateFileNo)
    targetFileNo=`echo "${targetStartFrameNo} + ${i}" | bc`
    targetFileName=$(printf "${imageFilePattern}.png" $targetFileNo)
    echo " ln -f -s ../../${updateFramesDir}/${updateFileName} ${targetFileName}"
    ln -f -s "../../${updateFramesDir}/${updateFileName}" "${targetFileName}"

    #add label (and marker if first frame)
    sed -i s/\\\(${updateFileName}\\\)/\\1\\t${eventName}/ ${targetSeqFileName}.tmp
    if [ $i == 0 ]; then
	sed -i s/\\\(${updateFileName}.*\\\)$/\\1\\t${modifiedEventMarker}/ ${targetSeqFileName}.tmp 							    
    fi
							   
    
done

#TODO do we need to fade-in/fade-out again
cd -
mv ${targetSeqFileName}.tmp ${targetSeqFileName}

echo "created seq file ${targetSeqFileName}"
