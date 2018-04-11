#!/bin/bash 

# checks whether the git repository in $1 has
# - no unstaged files
# - no uncommitted changes
# - no unpushed commits
#
# exits 0 when that's the case, prints a git status when not

set -o pipefail

cd $1


( if [[ $(git ls-files --other --directory --no-empty-directory --exclude-standard) ]]; then false; fi &&
  git diff-files --quiet -- && 
  git diff-index --quiet HEAD -- &&
  if [[ $(git log --branches --not --remotes) ]]; then false; fi
) || ((>&2 echo Unpushed changes in $1); git -c color.status=always status; false); 


