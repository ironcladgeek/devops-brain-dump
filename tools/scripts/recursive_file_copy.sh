#!/bin/bash

# Script: recursive_file_copy.sh
#
# Description: This script recursively copies files from a source directory to a destination directory,
# based on file suffix. It can optionally exclude files containing a specific string in their names.
# If files with similar names are encountered, they are renamed with a random 4-character suffix.
# Users can specify a custom comment symbol for the added path comment.
#
# Usage: ./recursive_file_copy.sh --src=<source_dir> --suffix=<file_suffix> [--dest=<destination_dir>] [--exclude=<exclude_string>] [--addr_prefix=<comment_symbol>]
#
# Arguments:
#   --src         : Source directory path (required)
#   --suffix      : File suffix to match, e.g., .py, .go (required)
#   --dest        : Destination directory path (optional, default: current directory)
#   --exclude     : String to exclude from file names (optional)
#   --addr_prefix : Comment symbol to use for the added path (optional, default: #)

# Function to print usage information
print_usage() {
    echo "Usage: $0 --src=<source_dir> --suffix=<file_suffix> [--dest=<destination_dir>] [--exclude=<exclude_string>] [--addr_prefix=<comment_symbol>]"
    echo "Example: $0 --src=./project --suffix=.go --dest=/out --exclude=__init --addr_prefix=//"
}

# Function to generate a random 4-character string
generate_random_suffix() {
    cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 4 | head -n 1
}

# Function to get relative path
get_relative_path() {
    local source=$1
    local target=$2

    local common_part=$source
    local result=""

    while [[ "${target#$common_part}" == "${target}" ]]; do
        common_part=$(dirname "$common_part")
        result="../$result"
    done

    if [[ "$common_part" == "/" ]]; then
        result="$result${target:1}"
    else
        result="$result${target#$common_part/}"
    fi

    echo "$result"
}

# Parse command line arguments
for arg in "$@"
do
    case $arg in
        --src=*)
        SRC="${arg#*=}"
        shift
        ;;
        --suffix=*)
        SUFFIX="${arg#*=}"
        shift
        ;;
        --dest=*)
        DEST="${arg#*=}"
        shift
        ;;
        --exclude=*)
        EXCLUDE="${arg#*=}"
        shift
        ;;
        --addr_prefix=*)
        ADDR_PREFIX="${arg#*=}"
        shift
        ;;
        *)
        # Unknown option
        echo "Unknown option: $arg"
        print_usage
        exit 1
        ;;
    esac
done

# Check if required arguments are provided
if [ -z "$SRC" ] || [ -z "$SUFFIX" ]; then
    echo "Error: Source directory and file suffix are required."
    print_usage
    exit 1
fi

# Set default values if not provided
DEST=${DEST:="./"}
ADDR_PREFIX=${ADDR_PREFIX:="#"}

# Create destination directory if it doesn't exist
mkdir -p "$DEST"

# Convert to absolute paths
SRC=$(cd "$SRC" && pwd)
DEST=$(cd "$DEST" && pwd)
BASEDIR=$(basename "$SRC")

# Main file copying logic
find "$SRC" -type f -name "*$SUFFIX" | while read -r file; do
    # Check if file should be excluded
    if [ -n "$EXCLUDE" ] && [[ $(basename "$file") == *"$EXCLUDE"* ]]; then
        continue
    fi

    # Get relative path
    rel_path=$(get_relative_path "$SRC" "$file")

    # Generate destination file path
    dest_file="$DEST/$(basename "$file")"

    # If destination file already exists, add random suffix
    if [ -e "$dest_file" ]; then
        random_suffix=$(generate_random_suffix)
        dest_file="${dest_file%$SUFFIX}_${random_suffix}${SUFFIX}"
    fi

    # Copy file and add original path as comment
    echo "$ADDR_PREFIX $BASEDIR/$rel_path" > "$dest_file"
    cat "$file" >> "$dest_file"

    echo "Copied: $file -> $dest_file"
done

echo "File copying completed."

