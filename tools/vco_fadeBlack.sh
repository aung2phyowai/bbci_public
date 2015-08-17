#!/bin/bash
set -ue
direction=$1 #direction ("in" or "out")
if [ $direction != "in" -a $direction != "out" ];
then
    echo "Illegal direction of fading: $direction, must be 'in' or 'out'"
    exit 1
fi
startNo=$2 #starting image ("1" -> 0000000001.png")
length=$3 #number of images in sequence
imageFilePattern='%010d'
sizeParam='1242x375'
blendIncr=$(echo "100 / ${length}" | bc)
for (( i=0; i< $length; i++ ))
do
    fileNo=`echo "${startNo} + ${i}" | bc`
    fileName=$(printf "${imageFilePattern}.png" $fileNo)
#    outFile=$(printf "${imageFilePattern}_fade${direction}.png" $fileNo)
    outFile=$fileName #replace file
    if [ $direction == "in" ];
    then
	blendFactor=`echo "${blendIncr} * ${i}" | bc`
    fi
    if [ $direction == "out" ];
    then
	blendFactor=`echo "100 - (${blendIncr} * (${i} + 1))" | bc`
    fi    
    echo "composite -blend ${blendFactor} ${fileName} -size ${sizeParam} xc:black -alpha Set 'tmp_${outFile}'"
    composite -blend ${blendFactor} ${fileName} -size ${sizeParam} xc:black -alpha Set "tmp_${outFile}"
    #delete and move in order not to replace target of symbolic link
    rm -f $outFile
    mv "tmp_${outFile}" $outFile
done
