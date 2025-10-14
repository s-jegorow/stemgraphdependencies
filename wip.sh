#!/bin/bash

# get all STEMgraph repos and save names as list
#gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt
echo "STEMgraph repolist saved as ./repolist.txt"

# loop through list and get each README.md
while read -r p; do
    if gh api /repos/STEMgraph/$p/contents/README.md --jq '.content' 2>/dev/null | base64 -d > README.md; then

# extract the meta-data for each result and dump it in a json file.
	    
    head -n 20 README.md | grep -Pzom1 '\{(?:[^{}"'\''\\]|\\.|"[^"\\]*(?:\\.[^"\\]*)*"|'\''[^'\''\\]*(?:\\.[^'\''\\]*)*'\''|(?0))*\}' | tr -d '\0' >> metadata_dump.json.tmp
    

	
    else
        echo "$p" >> no_readme.txt
    fi
done < repolist.txt
