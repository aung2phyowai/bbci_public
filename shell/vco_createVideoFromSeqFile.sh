#!/bin/sh
set -ue
seqFile=$1
fps=${2:-10}
seqFileBaseName=$(basename "$seqFile")
outFileName=${3:-${seqFileBaseName%.*}_${fps}fps.mp4}
startFrame=`head -n 1 ${seqFile} | sed -r 's%.*/([0-9]*).png%\1%'`
endFrame=`tail -n 1 ${seqFile} | sed -r 's%.*/([0-9]*).png%\1%'`
frameCount=`echo "${endFrame} - ${startFrame} + 1" | bc`
startFrameNoZeros=`echo "${startFrame} + 0" | bc`
#paths in seq file are relative to seq file location
firstFileAbsolutePath=`pwd`/`dirname ${seqFile}`/`head -n 1 ${seqFile}`
filePattern=`echo ${firstFileAbsolutePath} | sed "s/${startFrame}/%10d/"`
echo "Generating ${outFileName}, a ${fps}-fps video from ${seqFileBaseName%.*} with ${frameCount} frames (${startFrame}-${endFrame}) based on pattern ${filePattern}"
ffmpegCmd="ffmpeg -f image2 -framerate $fps -start_number ${startFrameNoZeros} -i ${filePattern} -vframes ${frameCount} -c:v libx264 ${outFileName}"
echo "executing ${ffmpegCmd}"
${ffmpegCmd}
echo "The video can be found at ${outFileName}"
