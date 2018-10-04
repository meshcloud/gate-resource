#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_check_from_head() {
  local repo=$(init_repo)
  local ref=$(make_commit $repo)

  local gate_ref=$(make_commit_to_file $repo "my-gate/1234")

  check_gate $repo "my-gate" | jq -e '
    . == [{"gate": "my-gate", "passed": "1234"}]
  '
}

# to do: test empty commit
# todo: test consecutive commits emmit latest only
 
run it_can_check_from_head