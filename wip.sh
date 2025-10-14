#!/bin/bash

# get all STEMgraph repos and save names as list
#gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt
echo "STEMgraph repolist saved as ./repolist.txt"

# loop through list and get each README.md
while read -r p; do
        if gh api /repos/STEMgraph/$p/contents/README.md --jq '.content' 2>/dev/null | base64 -d > readme.txt; then
                echo "$p: "
                grep depends_on readme.txt
        else
                echo "$p" >> no_readme.txt
        fi
done < repolist.txt
