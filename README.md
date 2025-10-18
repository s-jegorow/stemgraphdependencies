# STEMgraph Dependency Parser

Parses all STEMgraph repositories and generates a JSON-LD dependency graph.

## Using

- `gh` (GitHub CLI)
- `jq` - JSON processor

## Usage

```bash
./json-parser.sh
```

Outputs: `jsonld.json`

## What it does

1. Fetches all repos from STEMgraph GitHub org
2. Extracts dependency metadata from README files  
3. Converts to JSON-LD format with logic nodes - fixes a few issues with the dependencies and uses the AND/OR connections
4. Cleans up


## Future plans
- fix the issues with the repos and remove the workarounds in the parser
- add labels, keywords and titles to the nodes
- Mermaid diagram generation
- Other visualization formats

