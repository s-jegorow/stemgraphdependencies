#!/bin/bash

# get all STEMgraph repos and save names as list
#gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt
#echo "STEMgraph repolist saved as ./repolist.txt"

# loop through list and get / decode  each README.md
while read -r p; do
  if gh api /repos/STEMgraph/"$p"/contents/README.md --jq '.content' 2>/dev/null | base64 -d > README.md; then


# get meta 
 
    meta=$(head -n 20 README.md | grep -Pzom1 '\{(?:[^{}"'\''\\]|\\.|"[^"\\]*(?:\\.[^"\\]*)*"|'\''[^'\''\\]*(?:\\.[^'\''\\]*)*'\''|(?0))*\}' | tr -d '\0')


# parse meta to extract dependencies / ignore AND / empty values
    
    if [ -n "$meta" ]; then
      printf '%s\n' "$meta" >> metadata_dump.json.tmp

      {
        '{
  repo: $p,
  depends_on: (
    .depends_on as $d
    | if ($d|type=="array" and ($d[0]|tostring|test("^(AND|OR)$")))
      then { op: ($d[0]|tostring|ascii_upcase),
             ids: ($d[1:]|map(select(type=="string")|select(test("^[0-9a-fA-F-]{36}$")))) }
      else { op: "AND",
             ids: ($d|map(select(type=="string")|select(test("^[0-9a-fA-F-]{36}$")))) }
      end
  )
}
        echo
      } >> deps.txt
    fi

# when there is no README.md 
else
    echo "$p" >> no_readme.txt
  fi
done < repolist.txt
