# source this file in bash
vco_repo_tool_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
PATH="$PATH:${vco_repo_tool_dir}"
echo "added ${vco_repo_tool_dir} to PATH"
