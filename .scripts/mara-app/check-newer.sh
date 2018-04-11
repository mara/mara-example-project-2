#!/bin/bash 

# checks whether the git repository in $1 has newer tags available 

set -o pipefail

cd $1

git fetch --all --quiet 2>&1

if [[ $(git tag) ]]; then
   current_tag=`git describe --tags`
   origin_head_tag=`git describe origin/master --tags`
   if [ $current_tag != $origin_head_tag ]; then
       echo -e "\033[32m newer version available for $1 ($current_tag -> $origin_head_tag)\033[0m"
   fi
fi



