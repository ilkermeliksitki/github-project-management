#!/bin/bash
set -euo pipefail

# get the list of repos linked to the project into the array 'repos'
mapfile -t linked_repos < <(../get-project-linked-repos/get_project_linked_repos.sh)

# create an associative array to hold the labels and their colors
declare -A mutual_labels

# add the mutual labels with their colors, extend if neccessary
mutual_labels["overdue"]="#4fd0bb"
mutual_labels["noduedate"]="#38ff9c"
mutual_labels["reading"]="#40f5a2"

for repo in "${linked_repos[@]}"; do
    echo $repo
    for label in "${!mutual_labels[@]}"; do
        color=${mutual_labels[$label]}
        echo "  - $label: $color"
        gh label create "$label" --color "$color" --repo "$repo" --force
    done 
done
