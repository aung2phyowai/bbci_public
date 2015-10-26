#!/bin/bash
sourceDataDir=$1
targetDataDir=$2
targetImageDir=${targetDataDir}/kitti/images/final/
targetSeqDir=${targetDataDir}/kitti/seqs/final/
mkdir -p ${targetImageDir}
mkdir -p ${targetSeqDir}
echo "copying images files and replacing links with target"
rsync -azh --checksum --copy-links --copy-dirlinks --info=PROGRESS2 ${sourceDataDir}/kitti/images/final/ ${targetImageDir}
echo "copying sequence files"
rsync -azh --copy-links --copy-dirlinks --info=PROGRESS2 ${sourceDataDir}/kitti/seqs/final/ ${targetSeqDir}
