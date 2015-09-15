#!/bin/bash
curDir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
feedbackDir="${curDir}/../feedbacks"
export PYTHONPATH="${feedbackDir}" 
for seqFile in $*
do
#    echo "validating $seqFile"
    python -c "import seq_file_utils; seq_file_utils.validate_seq_file('${seqFile}')"
done
