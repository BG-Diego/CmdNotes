# CmdNotes

CmdNotes is a simple tool to manage shell commands with descriptions.

## Features

- Add commands with descriptions
- Search commands with fuzzy finder (`fzf`)

## Usage

```bash
cmdnotes add "ps aux"
# You will be prompted for a description

cmdnotes search
# Interactive search with fzf
# It only returns the command without copying it to the clipboard in order to type it manually to help you remember it later.

cmdnotes delete
# Interactive delete with fzf
# You will be prompted a confirmation message with the information of the command you want to delete
```

## Requirements
- bash
- fzf
- jq (JSON format)
