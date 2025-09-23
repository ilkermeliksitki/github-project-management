#!/usr/bin/env bash

USER="ilkermeliksitki"
PROJECT_NUMBER=5
MONTHS_AGO=6
CURSOR=null

query='
query ($user: String!, $projectNumber: Int!, $cursor: String) {
  user(login: $user) {
    projectV2(number: $projectNumber) {
      items(first: 100, after: $cursor) {
        pageInfo {
            hasNextPage
            endCursor
        }
        nodes {
          id
          content {
            ... on Issue {
              title
              closedAt
            }
            ... on PullRequest {
              title
              closedAt
            }
          }
        }
      }
    }
  }
}'

while true; do
    if [[ "$CURSOR" == null ]]; then
        vars=(-f user="$USER" -F projectNumber=$PROJECT_NUMBER -F cursor=null)
    else
        vars=(-f user="$USER" -F projectNumber=$PROJECT_NUMBER -F cursor="$CURSOR")
    fi
    response=$(gh api graphql -f query="$query" "${vars[@]}" --jq '.data.user.projectV2.items')

    # delete item from the project if it is closed more than MONTHS_AGO
    items=$(echo "$response" | jq -r '.nodes[]')
    echo $items | jq --compact-output '.' | while read -r item; do
        item_id=$(echo "$item" | jq -r '.id')
        closed_at=$(echo "$item" | jq -r '.content.closedAt')
        title=$(echo "$item" | jq -r '.content.title')
        if [[ "$closed_at" != null ]]; then
            closed_timestamp=$(date -d "$closed_at" +%s)
            months_ago_timestamp=$(date -d "$MONTHS_AGO months ago" +%s)

            if (( closed_timestamp < months_ago_timestamp )); then
                echo "🗑️ '$title' => Deletion"
                gh project item-delete $PROJECT_NUMBER --owner "$USER" --item-id "$item_id"
            else
                echo "✅ '$title' => No deletion"
            fi
        else
            echo "⏳ '$title' is still open => Skipping."
            continue
        fi
    done

    # pagination
    has_next_page=$(echo "$response" | jq -r '.pageInfo.hasNextPage')
    CURSOR=$(echo "$response" | jq -r '.pageInfo.endCursor')

    if [[ "$has_next_page" == "false" ]]; then
        break
    fi
done
