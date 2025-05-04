#!/bin/bash
# cmdnotes - Manage your own commands

# Actual script path
script_dir="$(cd "$(dirname "$0")" && pwd)"

FILE="$script_dir/data/my_commands.txt"

# Function to add a new command
add_command() {
    if (($# < 1)); then
        echo "❌ Usage: cmdnotes add <command>"
        exit 1
    fi
    # Join all arguments to form the command
    local command="$*"
    read -p "Description: " description
    read -p "Type (Makes searching easier): " type
    if [ -z "$description" ]; then
        echo "❌ You must enter a description."
        exit 1
    fi

    # Get current UTC timestamp in ISO 8601 format.
    # GNU date syntax
    local date_added

    # Ensure the data folder exists
    if [ ! -d "$script_dir/data/" ]; then
        mkdir -p "$script_dir/data"
        echo "📁 Folder successfully created: $script_dir"
    fi

    # If the file does not exist, create an empty JSON array.
    if [ ! -f "$FILE" ]; then
        echo "[]" >"$FILE"
    fi

    # Append the new entry to the JSON array using jq.
    # Create a temporary file to hold the updated JSON.
    local tmpfile
    tmpfile=$(mktemp)

    if jq --arg desc "$description" --arg cmd "$command" --arg typ "$type" \
        '. += [{"description": $desc, "command": $cmd, "type":$typ }]' "$FILE" >"$tmpfile"; then

        # Only move the temp file if jq succeeded
        mv "$tmpfile" "$FILE"
        echo "✅ Command successfully saved to $FILE"

    else
        echo "❌ Failed to add the command."
        rm -f "$tmpfile"
        exit 1
    fi
}

# Function to search for commands
search_command() {
    # Check if the JSON file exists
    if [ ! -f "$FILE" ]; then
        echo "The file $FILE does not exist."
        exit 1
    fi

    # Use jq to extract each entry as "description :: command"
    local selection

    if [[ "$1" == "-t" ]]; then
        shift
        TYPE="$1"
        # Filtramos el JSON por type y extraemos descripción::comando
        items=$(jq -r --arg t "$TYPE" \
            '.[] | select(.type == $t) | "\(.description):: \(.command)"' \
            "$FILE")
    else
        items=$(jq -r '.[] | "\(.description):: \(.command)"' "$FILE")
    fi

    # Lanzamos fzf sobre los ítems filtrados
    selection=$(printf "%s\n" "$items" | fzf --prompt="Search command > ")
    [[ -z "$selection" ]] && {
        echo "No se seleccionó nada."
        exit 0
    }

    echo -e "\nCommand:\n🔹${selection#*:: }\n"
}

# Function to delete a command
delete_command() {
    if [ ! -f "$FILE" ]; then
        echo "The file $FILE does not exist."
        exit 1
    fi

    local selection
    selection=$(jq -r 'to_entries[] | "\(.key)::\(.value.description)::\(.value.command)"' "$FILE" | fzf --prompt="Select command to delete > ")

    if [ -z "$selection" ]; then
        echo "No entry was selected."
        exit 1
    fi

    # Extract index from the command
    idx="${selection%%::*}"

    # Extract Description and Command
    rest="${selection#*::}"

    # Extract only the description:
    desc="${rest%%::*}"

    # Extract only the command:
    cmd="${rest#*::}"

    echo "Selected 🚩 Description: $desc. Command: $cmd"
    read -p "Are you sure you want to delete this entry? [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Deletion aborted."
        exit 0
    fi

    local tmpfile
    tmpfile=$(mktemp)
    if jq --argjson idx "$idx" 'del(.[$idx])' "$FILE" >"$tmpfile"; then
        mv "$tmpfile" "$FILE"
        echo "✅ Command deleted successfully from $FILE"
    else
        echo "❌ Failed to delete the command."
        rm -f "$tmpfile"
        exit 1
    fi
}

# Function to display usage information
show_usage() {
    echo "Usage: cmdnotes <operation> [arguments]"
    echo "Operations: add, search"
    exit 1
}

# Main processing: Check that an operation was provided
if (($# < 1)); then
    show_usage
fi

operation="$1"
shift

case "$operation" in
add)
    add_commad "$@"
    ;;
search)
    search_command "$@"
    ;;
delete)
    delete_command
    ;;
*)
    show_usage
    ;;
esac
