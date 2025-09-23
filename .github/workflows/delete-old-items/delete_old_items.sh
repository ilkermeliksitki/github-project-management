#!/usr/bin/env bash

USER="ilkermeliksitki"
PROJECT_NUMBER=5
LIMIT=1000
MONTHS_AGO=6

# fetch project items

items=$(gh project item-list "$PROJECT_NUMBER" --owner "$USER" --limit "$LIMIT" --format json --jq '.items[]')

echo "$items" | jq --compact-output '.' | while read -r item; do
    item_id=$(echo "$item" | jq --raw-output '.id')
    item_status=$(echo "$item" | jq --raw-output '.status')
    title=$(echo "$item" | jq --raw-output '.content.title')
    due_date=$(echo "$item" | jq --raw-output '."due date"')

    # if status is done and due date is older than $MONTHS_AGO months, delete the item from project
    if [[ "$item_status" == "done" ]]; then
        if [[ -n "$due_date" ]]; then
            due_date_epoch=$(date --date="$due_date" +%s)
            due_date_months_ago_epoch=$(date --date="$MONTHS_AGO months ago" +%s)
            if (( due_date_epoch < due_date_months_ago_epoch )); then
                echo "Deleting item => ${title}; with due date ${due_date}"
            fi
        fi
   fi
done
