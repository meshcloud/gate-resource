#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_check_from_head() {
  local repo=$(init_repo)
  local ref=$(make_commit $repo)

  check_uri $repo | jq -e "
    . == [{ref: $(echo $ref | jq -R .)}]
  "
}
 
run it_can_check_from_head