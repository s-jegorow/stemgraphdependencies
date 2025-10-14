Vorgehensweise:

1. Mit Github CLI die liste der Repos ziehen und filtern
gh repo list STEMgraph --limit 200 --json name -q '.[].name' > repolist.txt
