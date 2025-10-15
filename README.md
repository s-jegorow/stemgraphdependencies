# Build Release-Files from STEMgraph Challenge

This reusable GitHub Actions workflow automates the process of generating and publishing release files for STEMgraph Challenges. It creates HTML, Markdown, and LaTeX files from a `challenge.stemgraph` file and publishes them accordingly.

## Prerequisites

- **Repository Structure**: Ensure that your repository contains a `challenge.stemgraph` file in the root directory.

- **Access to `document-generator`**: The workflow utilizes the `STEMgraph/document-generator` repository to obtain the necessary Python scripts for file generation. Ensure this repository is accessible or that appropriate access rights are configured.

## Usage

To incorporate this workflow into your repository, create a workflow file (e.g., `.github/workflows/build-release.yml`) with the following content:

```yaml
name: Build and Release STEMgraph Challenge

on:
  push:
    tags:
      - '*'
  workflow_dispatch:

jobs:
  call-build-release:
    uses: STEMgraph/release_workflow/.github/workflows/build-release-files.yml@<TAG>
    secrets: inherit
```

## How It Works

The workflow comprises several jobs:

1. **build-release-files**: Generates artifacts (`index.html`, `README.md`, `challenge.tex`) from the `challenge.stemgraph` file.

2. **release-md**: Publishes the generated `README.md` to the `master` branch.

3. **release-latex**: Converts the LaTeX file into a PDF and creates a release with the PDF attached.

4. **release-html**: Publishes the generated `index.html` to the `gh-pages` branch for deployment via GitHub Pages.

## Notes

- **Permissions**: The workflow requires write permissions to the repository's contents to make changes to branches and create releases.

- **Dependencies**: The workflow automatically installs the necessary Python versions and packages, as well as additional tools like `librsvg2-bin` for SVG conversion.

- **Branch Names**: Ensure that the branch names referenced in the workflow (`master`, `gh-pages`) match those in your repository.

By integrating this workflow into your repository, you can efficiently and consistently automate the process of generating and publishing release files for your STEMgraph Challenges.

