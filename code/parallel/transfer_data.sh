#!/bin/bash
# Script automatically copy data from the local machine to the bwUnicluster
# options:
#       -s List of the session to be copied
#       -l location of the local data base
#       -h Flag. if present, the data is copied to $HOME in the remote server
#               if false, the data is copied to $WORK in the remote server
#
# Sebastian Castano
# 15. Dec. 2013

OPTIND=1

RDDATA="\$WORK"
while getopts "s:l:h" opt; do
    case "${opt}" in
    s)  
        SL=$OPTARG;;
    l)  
        LD=$OPTARG;;
    h)  
        RDDATA="\$HOME";;
    esac
done

if [ -f $SL ];
then
    echo "Transfering VP data from the session list file: "$SL
else
    echo "Error: $SL does not exist."
    exit
fi

if [ -d $LD ];
then
    echo "Getting data from: "$LD
else
    echo "Error: Directory $LD does not exist."
    exit
fi


echo -n "Username at bwUnicluster: "
read USERHPC
echo "Login to the HPC"
HOST=bwunicluster.scc.kit.edu
echo $SL
while read -r line;
do
    TRFDIR=$LD"/"$line
    if [ -d $line ];
    then
        echo "File '$line' does not exist"
    else
        echo "Transfering: "$TRFDIR
        ssh $USERHPC"@"$HOST "mkdir -p $RDDATA/data/bbciRaw" < /dev/null
        rsync -avz --ignore-existing $TRFDIR $USERHPC"@"$HOST:"$RDDATA/data/bbciRaw" < /dev/null
    fi
done < $SL
