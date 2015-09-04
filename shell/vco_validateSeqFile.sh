#!/bin/bash
curDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
feedbackDir="${curDir}/../feedbacks"
export PYTHONPATH="${feedbackDir}" 
for seqFile in $*
do
#    echo "validating $seqFile"
    python -c "import vco_utils; vco_utils.validate_seq_file('${seqFile}')"
done
