#!/bin/bash

# get all STEMgraph repos and save names as list
#gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt
echo "STEMgraph repolist saved as ./repolist.txt"

# loop through list and get each README.md
while read p; do
	gh api /repos/STEMgraph/$p/contents/README.md --jq '.content' | base64 -d > readme.txt
	echo "$p: "
	grep depends_on readme.txt
done < repolist.txt
