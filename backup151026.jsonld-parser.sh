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
      #Get UUID from the meta
      uuids=$(printf '%s\n' "$meta" | jq -r '
      .depends_on // [] |
      (if type=="array" then .[] else . end) |
      tostring |
      sub(".*/"; "") |
      select(. != "AND" and . != "")
    ' | sed 's/[][]//g; s/"//g; s/,/\n/g' | grep -E '^[0-9a-fA-F-]{36}$')

    # Template for the JSONLD file
    printf '%s\n' "$uuids" | jq -Rn --arg id "$p" '
      [inputs | select(length>0)] as $ids
      | {
          "@id": ("STEMgraph:" + $id),
          "@type": "Exercise",
          "dependsOn": ($ids | map("STEMgraph:" + .))
        }
    '
    echo ','
  } >> deps.txt.tmp
fi

# when there is no README.md 
else
    echo "$p" >> no_readme.txt
  fi
done < repolist.txt.tmp

# create a new jsonld-template file with fixed metadata
echo '{
  "@context": {
    "STEMgraph": "https://github.com/STEMgraph/",
    "schema": "http://schema.org/",
    "Exercise": "schema:LearningResource",
    "url": { "@id": "schema:url", "@type": "@id" },
    "dependsOn": { "@id": "schema:competencyRequired", "@type": "@id" }
  },
  "@graph": [' > jsonld-template.json

# loop through deps.txt.tmp
while read -r line; do
  echo "$line" >> jsonld-template.json
done < deps.txt.tmp

# close JSON structure
echo ']}' >> jsonld-template.json

tail -3 jsonld-template.json | sed 's/,/ /g' >> jsonld-template.json
