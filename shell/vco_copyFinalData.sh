#!/bin/bash
sourceDataDir=$1
targetDataDir=$2
echo "copying images files and replacing links with target"
rsync -azh --copy-links --copy-dirlinks --info=PROGRESS2 ${sourceDataDir}/kitti/images/final/ ${targetDataDir}/kitti/images/final/
echo "copying sequence files"
rsync -azh --copy-links --copy-dirlinks --info=PROGRESS2 ${sourceDataDir}/kitti/seqs/final/ ${targetDataDir}/kitti/seqs/final/
