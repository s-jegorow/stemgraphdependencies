Vorgehensweise:

1. Mit Github CLI die liste der Repos ziehen und filtern
gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt

2. Inhalt der README.md als plain text:
gh api /repos/{owner}/{repo}/contents/README.md --jq '.content' | base64 -d

3. Mit Regex die Meta-Daten am Anfang in eine JSON Datei speichern.

JSON-LD: json-ld.org
Example data in deptree-example.json
