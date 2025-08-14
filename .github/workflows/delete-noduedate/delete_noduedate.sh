#!/bin/bash

# this script checks issues in a GitHub project (currently the project number 5) and removes the "noduedate" label from 
# issues that have a due date.

PROJECT_ID="PVT_kwHOBTCXXM4AzNYo"
PROJECT_NUMBER=5
OWNER="@me"

TODAY=$(date -u +%Y-%m-%d)

# fetch project items
items=$(gh project item-list $PROJECT_NUMBER --format json --jq '.' --owner "$OWNER" --limit 1000 | jq -c '.items[]')
if [[ $? -ne 0 ]]; then
  echo "Failed to fetch project items. Please check your GitHub CLI configuration."
  exit 1
fi

while IFS= read -r item; do
  TITLE=$(echo "$item" | jq -r '.title')
  DUE_DATE=$(echo "$item" | jq -r '.["due date"]')
  ISSUE_URL=$(echo "$item" | jq -r '.content.url')
  STATUS=$(echo "$item" | jq -r '.status')

  echo "Processing: $TITLE"

  # skip items that are already done
  if [[ "$STATUS" == "done" ]]; then
    echo -e "Item is already done, $ISSUE_URL\n"
    continue
  fi

  # fetch issue labels
  labels=$(gh issue view $ISSUE_URL --json labels --jq '.labels[].name')
  if [[ $? -ne 0 ]]; then
    echo "Failed to fetch labels for issue $ISSUE_URL."
    exit 1
  fi

  # check if the item has a due date
  marked_noduedate=false
  for label in $labels; do
    if [[ "$label" == "noduedate" ]]; then
      echo -e "Item is already marked as noduedate, $label, $ISSUE_URL\n"
      marked_noduedate=true
      break
    fi
  done

  # if the issue has a due date and also "noduedate" label, remove the label
  if [[ "$DUE_DATE" != "null" && "$marked_noduedate" == true ]]; then
    echo -e "Item has a due date but is marked as noduedate. Removing label, $ISSUE_URL\n"
    gh issue edit $ISSUE_URL --remove-label "noduedate"
    if [[ $? -ne 0 ]]; then
      echo "Failed to remove 'noduedate' label from issue $ISSUE_URL."
      exit 1
    fi
    continue
  fi

done <<< "$items"

