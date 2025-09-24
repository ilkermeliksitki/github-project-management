#!/bin/bash

USER=${1:-"ilkermeliksitki"}
PROJECT_NUMBER=${2:-5}

gh api graphql -f query='
  query($user: String! $number: Int! $endCursor: String){
    user(login: $user){
      projectV2(number: $number) {
        title
        repositories(first: 100, after: $endCursor) {
          nodes {
            nameWithOwner
          }
          pageInfo{
            hasNextPage,
            endCursor
          } 
        }
      }
    }
  }' -f user="$USER" -F number=$PROJECT_NUMBER --paginate --jq '.'
