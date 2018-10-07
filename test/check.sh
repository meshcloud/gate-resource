#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_check_from_head() {
  local repo=$(init_repo)
  local ref=$(make_commit $repo)

  local gate_ref=$(make_commit_to_file $repo "my-gate/1234")

  check_gate $repo "my-gate" | jq -e "
    . == [{ref: $(echo $gate_ref | jq -R .)}]
  "
}

it_can_check_empty_repo() {
  local repo=$(init_repo)
  
  check_gate $repo "my-gate" | jq -e '
    . == []
  '
}

it_can_check_empty_gate() {
  local repo=$(init_repo)
  
  make_commit $repo
  make_commit_to_file $repo "other-gate/1234"

  check_gate $repo "my-gate" | jq -e '
    . == []
  '
}

it_can_check_from_a_ref() {
  local repo=$(init_repo)
  
  local gate_ref1=$(make_commit_to_file $repo "my-gate/1")
  local gate_ref2=$(make_commit_to_file $repo "my-gate/2")
  local non_gate_ref2=$(make_commit_to_file $repo "other-gate/1")
  local gate_ref3=$(make_commit_to_file $repo "my-gate/3")

  check_gate_at_ref $repo "my-gate" "$gate_ref2" | jq -e "
    . == [
      {ref: $(echo $gate_ref2 | jq -R .)},
      {ref: $(echo $gate_ref3 | jq -R .)}
    ]
  "
}

run it_can_check_from_head
run it_can_check_empty_repo
run it_can_check_empty_gate
run it_can_check_from_a_ref