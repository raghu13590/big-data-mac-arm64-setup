#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

PROJECT_NAME="$1"
if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: PROJECT_NAME not provided.${NC}"
    exit 1
fi

# Temporary files for dependency resolution
dep_file=$(mktemp /tmp/deps.XXXXXX)
project_file=$(mktemp /tmp/projects.XXXXXX)
trap "rm -f $dep_file $project_file" EXIT

# Function to find all dependencies recursively
find_all_deps() {
    local project="$1"
    local parent="$2"

    if [ -n "$parent" ]; then
        echo "$project $parent" >> "$dep_file"
    fi

    if grep -qw "$project" "$project_file"; then return; fi
    echo "$project" >> "$project_file"

    # The script is expected to be run from a service directory, e.g., apps/zookeeper
    # So we search for other services in the parent directory.
    local project_dir=$(find .. -maxdepth 2 -type f -name ".env" -exec grep -l "PROJECT_NAME=$project" {} + | xargs dirname | head -n 1)
    if [ -z "$project_dir" ]; then
        echo -e "${RED}Error: Could not find directory for project: $project${NC}"
        exit 1
    fi

    local deps=$(grep '^DEPENDENCIES=' "$project_dir/.env" | cut -d= -f2 | tr -d '[:space:]')
    if [ -n "$deps" ] && [ "$deps" != "null" ]; then
        for d in $(echo $deps | tr ',' ' '); do
            find_all_deps "$d" "$project"
        done
    fi
}

echo -e "${GREEN}Resolving dependency tree for $PROJECT_NAME...${NC}"
find_all_deps "$PROJECT_NAME"

# Use tsort to find order and check for circular dependencies
if ! sorted_deps=$(tsort "$dep_file" 2>/dev/null); then
    if ! tsort "$dep_file" >/dev/null 2>&1; then
        echo -e "${RED}Error: Circular dependency detected. Please check your .env files.${NC}"
        exit 1
    fi
    # If tsort fails but not because of a cycle, it might be a single-node graph.
    # In that case, the project itself is the only thing.
    sorted_deps=$PROJECT_NAME
fi


echo -e "${GREEN}Dependency start order:${NC} $sorted_deps"

for dep in $sorted_deps; do
    if [ "$dep" = "$PROJECT_NAME" ]; then continue; fi
    dep_dir=$(find .. -maxdepth 2 -type f -name ".env" -exec grep -l "PROJECT_NAME=$dep" {} + | xargs dirname | head -n 1)
    echo -e "${GREEN}--- Starting dependency '$dep' in '$dep_dir'...${NC}"
    make -C "$dep_dir" up-minimal
    echo -e "${GREEN}--- Finished dependency '$dep' ---${NC}"
done