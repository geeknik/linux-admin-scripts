#!/bin/bash

# Function to display script usage
usage() {
    echo "Usage: $0 <source_file> <target_directory> <hosts_file> <ssh_key>"
    exit 1
}

# Check that the appropriate number of arguments are supplied
if [ "$#" -ne 4 ]; then
    usage
fi

# SOURCE FILE
SOURCE="$1"
# TARGET DIRECTORY/FILE
TARGET="$2"
# FILE CONTAINING LIST OF HOSTS
HOSTS="$3"
# SSH KEY
ID="$4"

# Function to copy files to remote hosts
copy_files() {
    if [ -f "$SOURCE" ]; then
        echo "File found, preparing to transfer"
        
        if [ -f "$HOSTS" ]; then
            while read -r server; do
                scp -i "$ID" -p "$SOURCE" "${server}:$TARGET"
            done < "$HOSTS"
        else
            echo "Hosts file \"$HOSTS\" not found"
            exit 1
        fi
    else
        echo "Source file \"$SOURCE\" not found"
        exit 1
    fi
}

# Call the copy_files function
copy_files
