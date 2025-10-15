#!/bin/bash

# get all STEMgraph repos and save names as list
gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt.tmp
echo "STEMgraph repolist saved as ./repolist.txt.tmp"

# loop through list and get / decode  each README.md
while read -r p; do
  if gh api /repos/STEMgraph/"$p"/contents/README.md --jq '.content' 2>/dev/null | base64 -d > README.md; then


# get meta 
 
meta=$(head -n 20 README.md | grep -v '"OR"' | grep -Pzom1 '\{(?:[^{}"'\''\\]|\\.|"[^"\\]*(?:\\.[^"\\]*)*"|'\''[^'\''\\]*(?:\\.[^'\''\\]*)*'\''|(?0))*\}' | tr -d '\0')

# parse meta to extract dependencies / ignore AND / empty values
    
    if [ -n "$meta" ]; then
      printf '%s\n' "$meta" >> metadata_dump.json.tmp

	      {
  printf "repo %s depends on:\n" "$p"
  printf '%s\n' "$meta" | jq -r '
    .depends_on // [] |
    (if type=="array" then .[] else . end) |
    tostring |
    sub(".*/"; "") |
    select(. != "AND" and . != "")
  ' \
  | sed 's/[][]//g; s/"//g; s/,/\n/g' \
  | grep -E '^[0-9a-fA-F-]{36}$'
  echo
} >> deps.txt.tmp

    fi

# when there is no README.md 
else
    echo "$p" >> no_readme.txt
  fi
done < repolist.txt.tmp
