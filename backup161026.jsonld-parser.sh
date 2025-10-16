#!/bin/bash

# get all STEMgraph repos and save names as list
gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt.tmp
echo "STEMgraph repo list saved as ./repolist.txt.tmp"

# create JSON-LD header 
cat > jsonld.tmp <<'EOF'
{
  "@context": {
    "STEMgraph": "https://github.com/STEMgraph/",
    "schema": "http://schema.org/",
    "owl": "http://www.w3.org/2002/07/owl#",
    "Exercise": "schema:LearningResource",
    "dependsOn": {
      "@id": "schema:competencyRequired",
      "@type": "@id"
    },
    "intersectionOf": {
      "@id": "owl:intersectionOf",
      "@type": "@vocab"
    },
    "unionOf": {
      "@id": "owl:unionOf",
      "@type": "@vocab"
    }
  },
  "@graph": [
EOF

echo "jsonld.tmp file created with header"

# loop through list and get / decode each README.md
echo "getting and decoding README.md files from Repolist"

while read -r p; do
  if gh api /repos/STEMgraph/"$p"/contents/README.md --jq '.content' 2>/dev/null | base64 -d > README.tmp; then

    # Extract JSON: remove HTML comments, take first 50 lines, validate with jq
    meta=$(sed 's/<!---//g; s/--->//g' README.tmp | head -50 | jq -c '.' 2>/dev/null)
    
    # Process if valid JSON with id field
    if [ -n "$meta" ] && echo "$meta" | jq -e '.id' >/dev/null 2>&1; then
      printf '%s\n' "$meta" >> metadata_dump.json.tmp

      # Generate all nodes from metadata and append directly to deps file
      printf '%s\n' "$meta" | jq -c --arg repo "$p" '
        def normalize:
          if type == "string" then
            if test("^STEMgraph:") then .
            elif test("^https?://github.com/STEMgraph/") then
              "STEMgraph:" + (sub(".*STEMgraph/"; ""))
            elif test("^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$") then
              "STEMgraph:" + .
            else
              "STEMgraph:" + .
            end
          elif type == "array" then map(normalize)
          else .
          end;
        
        def extract_id:
          if startswith("STEMgraph:") then .[11:] else . end;
        
        def process:
          if type == "string" then
            normalize as $n |
            {ref: $n, nodes: [{("@id"): $n, ("@type"): "Exercise"}]}
          
          elif type == "array" and length == 1 then
            .[0] | process
          
          elif type == "array" and (.[0] == "AND" or .[0] == "OR") then
            .[0] as $op | .[1:] as $items |
            ($items | map(process)) as $processed |
            (($op + "-" + ($processed | map(.ref | extract_id) | join("-")))) as $id |
            {
              ref: ("STEMgraph:" + $id),
              nodes: (($processed | map(.nodes) | add) + [{
                ("@id"): ("STEMgraph:" + $id),
                ("@type"): "owl:Class",
                (if $op == "AND" then "intersectionOf" else "unionOf" end): ($processed | map(.ref))
              }])
            }
          
          elif type == "array" and length > 1 then
            map(process) as $processed |
            ("AND-" + ($processed | map(.ref | extract_id) | join("-"))) as $id |
            {
              ref: ("STEMgraph:" + $id),
              nodes: (($processed | map(.nodes) | add) + [{
                ("@id"): ("STEMgraph:" + $id),
                ("@type"): "owl:Class",
                intersectionOf: ($processed | map(.ref))
              }])
            }
          
          else
            {ref: null, nodes: []}
          end;
        
        ((.id // $repo) | tostring) as $eid |
        if .depends_on then
          (.depends_on | process) as $result |
          if $result.ref then
            ({("@id"): ("STEMgraph:" + $eid), ("@type"): "Exercise", dependsOn: $result.ref}),
            ($result.nodes | .[])
          else
            {("@id"): ("STEMgraph:" + $eid), ("@type"): "Exercise"}
          end
        else
          {("@id"): ("STEMgraph:" + $eid), ("@type"): "Exercise"}
        end
      ' >> deps.txt.tmp
    fi
  fi
done < repolist.txt.tmp

# Finalize JSON-LD
echo "Finishing the jsonld.tmp file"
if [ -s deps.txt.tmp ]; then
  # Remove duplicates while preserving order, add commas
 sort -u deps.txt.tmp | sed 's/$/,/' > deps_dedup.txt.tmp

  # Add all but last line
  head -n -1 deps_dedup.txt.tmp >> jsonld.tmp
  # Add last line without comma
  tail -n 1 deps_dedup.txt.tmp | sed 's/,$//' >> jsonld.tmp
fi

echo '  ]
}' >> jsonld.tmp

# Sloppy Workarounds 1.) OR prefix in IDs (sed removes first letter, causing -R- instead of -OR-)
sed -i 's/-R-/-OR-/g' jsonld.tmp

echo "JSON-LD generated: ./jsonld.tmp"
cp jsonld.tmp jsonld.json
rm *.tmp
