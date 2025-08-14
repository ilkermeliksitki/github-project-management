#!/bin/bash

PROJECT_ID="PVT_kwHOBTCXXM4AzNYo"
PROJECT_NUMBER=5
OWNER="@me"

TODAY=$(date -u +%Y-%m-%d)

# fetch project items
items=$(gh project item-list $PROJECT_NUMBER --format json --jq '.' --owner "$OWNER" --limit 1000 | jq -c '.items[]')
if [[ $? -ne 0 ]]; then
  echo "Failed to fetch project items."
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
    echo "Failed to fetch labels for issue: $ISSUE_URL"
    exit 1
  fi

  marked_noduedate=false
  for label in $labels; do
    if [[ "$label" == "noduedate" ]]; then
      echo -e "Item is already marked as noduedate, $label, $ISSUE_URL\n"
      marked_noduedate=true
      break
    fi
  done

  # skip if already marked as noduedate
  if [[ $marked_noduedate == true ]]; then
    echo -e "Item is already marked as noduedate, $ISSUE_URL\n"
    continue
  fi

  # add `noduedate` label if the issue has no due date
  if [[ $DUE_DATE == "null" ]]; then
    echo -e "Item has no due date, labeling as noduedate, $ISSUE_URL\n"
    gh issue edit $ISSUE_URL --add-label "noduedate"
    if [[ $? -ne 0 ]]; then
      echo "Failed to add label 'noduedate' to issue: $ISSUE_URL"
      exit 1
    fi
  else
    echo -e "Item has a due date, skipping, $ISSUE_URL\n"
  fi

done <<< "$items"

