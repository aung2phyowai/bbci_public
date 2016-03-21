#!/bin/bash
if [ -n "${SCRIPT_FLAGS}" ] ; then
   ## but if positional parameters are already present
   ## we are going to ignore $SCRIPT_FLAGS
   if [ -z "${*}"  ] ; then
      set -- ${SCRIPT_FLAGS}
   fi
fi
module load math/matlab/R2014a
echo "Running SPoC for "$1
matlab -nodesktop -nojvm -r "demo_SPoCGridMain('$1')"
