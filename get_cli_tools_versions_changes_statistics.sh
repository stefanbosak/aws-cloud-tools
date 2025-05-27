#!/bin/bash
echo "CLI tools versions statistics"
echo "============================="
echo "tool; amount of changes"
echo "-----------------------"

for i in $( awk -F"=" '{print $1}' PUSHED_CLI_VERSIONS.txt); do echo -ne "${i}; "; git log --since="3 years ago" -- PUSHED_CLI_VERSIONS.txt | \
awk '/commit/{print $NF}' | xargs -n 1 git show | grep "+${i}" | wc -l; done | sort -t';' -k2 -nr
