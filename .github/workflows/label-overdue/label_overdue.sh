#!/bin/bash

PROJECT_ID="PVT_kwHOBTCXXM4ArDDM"
PROJECT_NUMBER=3
OWNER="@me"

TODAY=$(date -u +%Y-%m-%d)

# fetch project items
items=$(gh project item-list $PROJECT_NUMBER --format json --jq '.' --owner "$OWNER" --limit 1000 | jq -c '.items[]')

while IFS= read -r item; do
  TITLE=$(echo "$item" | jq -r '.title')
  DUE_DATE=$(echo "$item" | jq -r '.["due date"]')
  ISSUE_URL=$(echo "$item" | jq -r '.content.url')
  STATUS=$(echo "$item" | jq -r '.status')

  echo "Processing: $TITLE"

  # skip the item if it is already done
  if [[ "$STATUS" == "done" ]]; then
    echo -e "Item is done, $ISSUE_URL\n"
    continue
  fi

  # if the due date is not set, skip the item. it is not possible to calculate overdue
  if [[ "$DUE_DATE" == "null" ]]; then
    echo -e "Due date is not set, $ISSUE_URL\n"
    continue
  fi

  # calculate the remaining days
  DAYS_REMAINING=$(( ( $(date -d "$DUE_DATE" +%s) - $(date -d "$TODAY" +%s) ) / 86400 ))

  # fetch issue labels
  labels=$(gh issue view $ISSUE_URL --json labels --jq '.labels[].name')

  # check if the issue is already marked as overdue or not
  marked_overdue=false
  for label in $labels; do
    if [[ "$label" == "overdue" ]]; then
      marked_overdue=true
      break
    fi
  done

  # it is already marked as overdue, no need to check further, the job is already done
  if [[ "$marked_overdue" == true ]]; then
    echo -e "Item is already marked as overdue, $ISSUE_URL\n"
    continue
  fi

  # for overdue items, add a `overdue` label
  if [[ "$DAYS_REMAINING" -lt 0 && "$marked_overdue" == false ]]; then
    echo -e "Item is overdue labelling, $ISSUE_URL\n"
    gh issue edit $ISSUE_URL --add-label "overdue"
    sleep 3
  else
    echo -e "Item is not overdue, $ISSUE_URL\n"
  fi

done <<< "$items"

