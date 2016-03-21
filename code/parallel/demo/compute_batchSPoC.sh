#!/bin/bash

while read -r line;
do 
   if [ ! -z "$line" ];
   then
	echo "Submitting single_VP.sh "$line
	msub -q singlenode -l nodes=1:ppn=8,walltime=2:00:00,pmem=5gb -v SCRIPT_FLAGS="$line" single_VP.sh
   fi
done < $1
