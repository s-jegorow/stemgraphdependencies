#!/bin/bash

# get all STEMgraph repos and save names as list
#gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt
echo "STEMgraph repolist saved as ./repolist.txt"

# loop through list and get each README.md
while read -r p; do
  if gh api /repos/STEMgraph/"$p"/contents/README.md --jq '.content' 2>/dev/null | base64 -d > README.md; then


# Meta aus README ziehen
    meta=$(head -n 20 README.md | grep -Pzom1 '\{(?:[^{}"'\''\\]|\\.|"[^"\\]*(?:\\.[^"\\]*)*"|'\''[^'\''\\]*(?:\\.[^'\''\\]*)*'\''|(?0))*\}' | tr -d '\0')


# meta mit jq verarbeiten    
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
        '
        echo
      } >> deps.txt
    fi

else
    echo "$p" >> no_readme.txt
  fi
done < repolist.txt
