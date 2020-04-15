#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_get_from_regular_version() {
  local repo=$(init_repo)
  local dest=$TMPDIR/destination
  local gate="my-gate"
  local item="1234"

  local gate_ref=$(make_commit_to_file $repo "$gate/$item")

  echo "xxxx"
  git -C "$repo" branch -a 
  echo "xxxx"
  
  result=$(get_gate_at_ref "$repo" "$gate_ref" "$gate" "$dest")
  echo "$result" | jq -e '
    .version == { "ref": "'$gate_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "'$item'")
  '

  test $(cat $dest/passed) = "$item"
  test $(cat $dest/metadata) = "x"
}

it_can_get_from_none_version_and_skip_output() {
  local repo=$(init_repo)
  local dest=$TMPDIR/destination
  local gate="my-gate"
  local item="1234"

  local gate_ref="none"
  result=$(get_gate_at_ref "$repo" "$gate_ref" "$gate" "$dest")
  echo "$result" | jq -e '
    .version == { "ref": "none" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "none")
  '

  test ! -f $dest/passed
  test ! -f $dest/metadata
}


it_can_get_from_autoclose_version() {
  local repo=$(init_repo)
  local dest=$TMPDIR/destination
  local gate="autogate"
  local item="1234"

  mkdir -p $repo/$gate
  echo "x" >> "$repo/$gate/$item.autoclose"
  local intial_ref=$(make_commit_with_all_changes $repo)

  mv "$repo/$gate/$item.autoclose" "$repo/$gate/$item"
  local autoclose_ref=$(make_commit_with_all_changes $repo)

  result=$(get_gate_at_ref "$repo" "$autoclose_ref" "$gate" "$dest")
  echo "$result" | jq -e '
    .version == { "ref": "'$autoclose_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "'$item'")
  '

  test $(cat $dest/passed) = "$item"
  test $(cat $dest/metadata) = "x"
}

run it_can_get_from_regular_version
run it_can_get_from_none_version_and_skip_output
run it_can_get_from_autoclose_version