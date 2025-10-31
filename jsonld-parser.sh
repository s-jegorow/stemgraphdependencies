#!/bin/bash

#PREPERATION
# get all STEMgraph repos and save names as list
gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt.tmp
echo "STEMgraph repo list saved as ./repolist.txt.tmp"

parsed=0
total=$(wc -l < repolist.txt.tmp)

# Create JSON-LD header 
cat > jsonld.tmp <<'EOF'
{
	"@context": {
		"schema": "http://schema.org/",
		"Exercise": "schema:LearningResource",
		"isBasedOn": "schema:isBasedOn",
		"stg": "https://github.com/STEMgraph/vocab#",
		"@base": "https://github.com/STEMgraph/"
	},
	"@graph": [
EOF

echo "jsonld.tmp file created with header"

# loop through list and get / decode each README.md
echo "getting and decoding README.md files from Repolist"






# PREPROCESSING

while read -r p; do

  # Extract JSON metadata from README

  meta=$(curl -H 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/STEMgraph/$p/contents/README.md 2>README.err | sed -n '/<!--/,/-->/p' | sed -n '/{/,/}/p' |  jq -c '.' 2>/dev/null)
  echo $meta
  sleep 2 



  # Validate metadata - returns "ok" or error message
  validation=$(echo "$meta" | jq -r --arg repo "$p" '
    def is_uuid: test("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$");
    def has_prefix: test("^STEMgraph:") or test("^https?://");
    
    def validate_depends:
      if type == "string" then
        if has_prefix then "contains_prefix"
        elif is_uuid then true
        else "invalid_uuid_format"
        end
      elif type == "array" and length == 0 then true
      elif type == "array" and (.[0] == "AND" or .[0] == "OR") then
        if length < 2 then "and_or_without_operands"
        else
          [.[1:] | .[] | validate_depends] | 
          if any(. != true) then (map(select(. != true)) | .[0])
          else true
          end
        end
      elif type == "array" then
        [.[] | validate_depends] |
        if any(. != true) then (map(select(. != true)) | .[0])
        else true
        end
      else "unexpected_type"
      end;
    
    if . == null or . == "" then "\($repo): no valid JSON metadata found"
    elif .id | not then "\($repo): missing id field"
    elif .depends_on and ((.depends_on | type) != "array") then "\($repo): depends_on is not an array"
    elif .depends_on then
      (.depends_on | validate_depends) as $result |
      if $result == true then "ok"
      else "\($repo): depends_on validation failed - \($result)"
      end
    else "ok"
    end
  ') 

  if [ "$validation" != "ok" ]; then
    echo "$validation" >> readme-errorlog.txt
    continue
  fi
  

# PROCESSING

  # Generate all nodes from metadata
  echo "$meta" | jq -c --arg repo "$p" '
      # Collect all UUIDs that need Exercise nodes
      def collect_all_uuids:
        if type == "string" then [.]
        elif type == "array" and length == 0 then []
        elif type == "array" and (.[0] == "AND" or .[0] == "OR") then
          [.[1:] | .[] | collect_all_uuids] | add
        elif type == "array" then
          [.[] | collect_all_uuids] | add
        else []
        end;
      
      # Process depends_on array into isBasedOn and hasAlternativeDependency
      def process_depends:
        if type == "array" and length == 0 then
          {isBasedOn: [], altDep: null}
        elif type == "array" and .[0] == "AND" then
          # Separate direct UUIDs and OR groups
          {
            isBasedOn: [.[1:] | .[] | select(type == "string")],
            altDep: (
              [.[1:] | .[] | select(type == "array" and .[0] == "OR")] |
              if length > 0 then
                .[0] | {
                  ("@type"): "stg:AlternativeDependency",
                  ("stg:isBasedOnOptions"): .[1:]
                }
              else null
              end
            )
          }
        elif type == "array" and .[0] == "OR" then
          # Everything goes into alternative dependency
          {
            isBasedOn: [],
            altDep: {
              ("@type"): "stg:AlternativeDependency",
              ("stg:isBasedOnOptions"): .[1:]
            }
          }
        elif type == "array" then
          # Implicit AND - all direct UUIDs
          {
            isBasedOn: .,
            altDep: null
          }
        else
          {isBasedOn: [], altDep: null}
        end;
      
      ((.id // $repo)) as $eid |
      
      if .depends_on then
        # Process dependencies
        (.depends_on | process_depends) as $deps |
        (.depends_on | collect_all_uuids) as $all_uuids |
        
        # Output main Exercise node
        (
          {
            ("@id"): $eid,
            ("@type"): "Exercise"
          } + 
          (if ($deps.isBasedOn | length) > 0 then {isBasedOn: $deps.isBasedOn} else {} end) +
          (if $deps.altDep then {("stg:hasAlternativeDependency"): $deps.altDep} else {} end)
        ),
        # Output Exercise nodes for all referenced UUIDs
        ($all_uuids | unique | .[] | {("@id"): ., ("@type"): "Exercise"})
      else
        # No dependencies
        {("@id"): $eid, ("@type"): "Exercise"}
      end
  ' >> deps.txt.tmp
  ((parsed++))
done < repolist.txt.tmp







#POSTPROCESSING
# Finalize JSON-LD
echo "Finishing the jsonld.tmp file"
# Remove duplicates, add commas, and append to jsonld
sort -u deps.txt.tmp | sed 's/$/,/' | sed '$s/,$//' >> jsonld.tmp

echo '  ]
}' >> jsonld.tmp

# Merge duplicate Exercise entries (combine isBasedOn arrays and hasAlternativeDependency)
jq '.["@graph"] |= (
  group_by(."@id") | 
  map(
    if length > 1 then
      reduce .[] as $item ({}; 
        . + $item | 
        if .isBasedOn and $item.isBasedOn then
          .isBasedOn = ([.isBasedOn, $item.isBasedOn] | add | unique)
        else . end
      )
    else .[0] 
    end
  )
)' jsonld.tmp > jsonld.json

echo ""
echo "=========================================="
echo "JSON-LD generated: ./jsonld.json"
echo "Successfully parsed: $parsed / $total repos"
if [ -f readme-errorlog.txt ]; then
  error_count=$(wc -l < readme-errorlog.txt)
  echo "Errors logged: $error_count repos (see readme-errorlog.txt)"
fi
echo "=========================================="

rm *.tmp
