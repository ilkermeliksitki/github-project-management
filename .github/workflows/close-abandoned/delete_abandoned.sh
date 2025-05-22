#!/bin/bash

PROJECT_ID="PVT_kwHOBTCXXM4AzNYo"
PROJECT_NUMBER=5
OWNER="@me"

TODAY=$(date -u +%Y-%m-%d)

# fetch project items
items=$(gh project item-list $PROJECT_NUMBER --format json --jq '.' --owner "$OWNER" --limit 1000 | jq -c '.items[]')

while IFS= read -r item; do
  TITLE=$(echo "$item" | jq -r '.title')
  ISSUE_URL=$(echo "$item" | jq -r '.content.url')
  STATUS=$(echo "$item" | jq -r '.status')

  echo "Processing: $TITLE"

  # skip items that are already done
  if [[ "$STATUS" == "done" ]]; then
    echo -e "Item is already done, $ISSUE_URL\n"
    continue
  fi

  # close the issue if it's status is abandoned
  if [[ "$STATUS" == "abandoned" ]]; then
    echo -e "Closing issue: $ISSUE_URL\n"
    gh issue close "$ISSUE_URL" --comment "Closed by script on $TODAY, because it was abandoned."
    continue
  fi

done <<< "$items"

