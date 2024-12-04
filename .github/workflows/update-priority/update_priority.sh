#!/bin/bash

PROJECT_ID="PVT_kwHOBTCXXM4ArDDM"
PROJECT_NUMBER=3
PRIORITY_FIELD_ID="PVTSSF_lAHOBTCXXM4ArDDMzgiMfxE"
OWNER="@me"

TODAY=$(date -u +%Y-%m-%d)

# fetch project items
items=$(gh project item-list $PROJECT_NUMBER --format json --jq '.' --owner "$OWNER" --limit 1000 | jq -c '.items[]')

while IFS= read -r item; do
  ID=$(echo "$item" | jq -r '.id')
  TITLE=$(echo "$item" | jq -r '.title')
  DUE_DATE=$(echo "$item" | jq -r '.["due date"]')
  ISSUE_URL=$(echo "$item" | jq -r '.content.url')
  PRIORITY=$(echo "$item" | jq -r '.priority' | sed -E 's/[^a-zA-Z]+/ /g' | xargs) # only get alphanumeric characters
  STATUS=$(echo "$item" | jq -r '.status')
 
  echo "Processing: $TITLE"

  # skip items that are already done
  if [[ "$STATUS" == "done" ]]; then
    echo -e "Item is already done, $ISSUE_URL\n"
    continue
  fi

  # skip items that have no due date
  if [[ "$DUE_DATE" == "null" ]]; then
    echo -e "Item has no due date, $ISSUE_URL\n"
    continue
  fi

  # skip items that are already at highest priority
  if [[ "$PRIORITY" == "CRITICAL" ]]; then
    echo -e "Item is already at highest priority (CRITICAL), no update needed, $ISSUE_URL\n"
    continue
  fi

  # calculate the remaining days until the due date
  DAYS_REMAINING=$(( ( $(date -u -d "$DUE_DATE" +%s) - $(date -u -d "$TODAY" +%s) ) / 86400 ))

  echo "Remaining days: $DAYS_REMAINING, Priority: -$PRIORITY-"

  if [[ "$DAYS_REMAINING" -le 3 ]]; then
    if [[ "$PRIORITY" != "CRITICAL" ]]; then
       gh project item-edit --id $ID --project-id $PROJECT_ID --field-id $PRIORITY_FIELD_ID --single-select-option-id "fd8c0199"
       echo -e "Priority updated to CRITICAL, $ISSUE_URL\n"
     else
       echo -e "Priority is already CRITICAL, no update needed, $ISSUE_URL\n"
     fi
  elif [[ "$DAYS_REMAINING" -le 5 ]]; then
    if [[ "$PRIORITY" != "urgent" ]]; then
       gh project item-edit --id $ID --project-id $PROJECT_ID --field-id $PRIORITY_FIELD_ID --single-select-option-id "95a57acb"
       echo -e "Priority updated to URGENT, $ISSUE_URL\n"
     else
       echo -e "Priority is already URGENT, no update needed, $ISSUE_URL\n"
     fi
  elif [[ "$DAYS_REMAINING" -le 8 ]]; then
    if [[ "$PRIORITY" != "high" ]]; then
       gh project item-edit --id $ID --project-id $PROJECT_ID --field-id $PRIORITY_FIELD_ID --single-select-option-id "79628723"
       echo -e "Priority updated to HIGH, $ISSUE_URL\n"
     else
       echo -e "Priority is already HIGH, no update needed, $ISSUE_URL\n"
     fi
  elif [[ "$DAYS_REMAINING" -le 15 ]]; then
    if [[ "$PRIORITY" != "medium" ]]; then
       gh project item-edit --id $ID --project-id $PROJECT_ID --field-id $PRIORITY_FIELD_ID --single-select-option-id "0a877460"
       echo -e "Priority updated to MEDIUM, $ISSUE_URL\n"
     else
       echo -e "Priority is already MEDIUM, no update needed, $ISSUE_URL\n"
     fi
  else 
    if [[ "$PRIORITY" != "low" ]]; then
       gh project item-edit --id $ID --project-id $PROJECT_ID --field-id $PRIORITY_FIELD_ID --single-select-option-id "da944a9c"
       echo -e "Priority updated to LOW, $ISSUE_URL\n"
     else
       echo -e "Priority is already LOW, no update needed, $ISSUE_URL\n"
     fi
  fi

done <<< "$items"


