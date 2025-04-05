#!/bin/bash
# cmdnotes - Manage your own commands

# Actual script path
script_dir="$( cd "$(dirname "$0")" && pwd)"

FILE="$script_dir/data/my_commands.txt"


# Function to add a new command
add_command() {
    if (( $# < 1 )); then
        echo "❌ Usage: cmdnotes add <command>"
        exit 1
    fi
    # Join all arguments to form the command
    local command="$*"
    read -p "Description: " description
    if [ -z "$description" ]; then
        echo "❌ You must enter a description."
        exit 1
    fi

     # Get current UTC timestamp in ISO 8601 format.
    # GNU date syntax
    local date_added
    date_added=$(date --utc +"%Y-%m-%dT%H:%M:%SZ")

    # Verify if the data folder exists
    if [ ! -d "$script_dir/data/" ]; then
        mkdir -p "$script_dir/data"
        echo "📁 Folder successfully created: $script_dir"
    fi

      # If the file does not exist, create an empty JSON array.
    if [ ! -f "$FILE" ]; then
        echo "[]" > "$FILE"
    fi

     # Append the new entry to the JSON array using jq.
    # Create a temporary file to hold the updated JSON.
    local tmpfile
    tmpfile=$(mktemp)

    if jq --arg desc "$description" --arg cmd "$command" \
        '. += [{"description": $desc, "command": $cmd}]' "$FILE" > "$tmpfile"; then

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
    selection=$(jq -r '.[] | "\(.description):: \(.command)"' "$FILE" | fzf --multi --prompt="Search command > ")

    if [ -n "$selection" ]; then
         # Print only the command.
        echo -e "\nCommand:\n🔹${selection#*:: }\n"
    else
        echo "No entry was selected."
    fi
}

# Function to display usage information
show_usage() {
    echo "Usage: cmdnotes <operation> [arguments]"
    echo "Operations: add, search"
    exit 1
}

# Main processing: Check that an operation was provided
if (( $# < 1 )); then
    show_usage
fi

operation="$1"
shift

case "$operation" in
    add)
        add_command "$@"
        ;;
    search)
        search_command "$@"
        ;;
    *)
        show_usage
        ;;
esac

