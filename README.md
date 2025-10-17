# STEMgraph Dependency Parser

Parses all STEMgraph repositories and generates a JSON-LD dependency graph.

## Prerequisites

- `gh` (GitHub CLI) - authenticated
- `jq` - JSON processor

## Usage

```bash
./json-parser.sh
```

Outputs: `jsonld.json`

## What it does

1. Fetches all repos from STEMgraph GitHub org
2. Extracts dependency metadata from README files  
3. Converts to JSON-LD format with proper logic nodes for AND/OR dependencies
4. Cleans up


## Future plans
- add labels and titles to the nodes
- Mermaid diagram generation
- Other visualization formats

