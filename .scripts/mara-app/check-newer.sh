#!/bin/bash 

# checks whether the git repository in $1 has newer tags available 

set -o pipefail

cd $1

git fetch --all --quiet 2>&1

if [[ $(git tag) ]]; then
   current_tag=`git describe --tags`
   latest_tagged_commit=`git rev-list --tags --max-count=1`
   latest_tag=`git describe --tags $latest_tagged_commit`
   if [ $current_tag != $latest_tag ]; then
       echo -e "\033[32m newer version available for $1 ($current_tag -> $latest_tag)\033[0m"
   fi
fi



