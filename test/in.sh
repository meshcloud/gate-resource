#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_get_from_version() {
  local repo=$(init_repo)
  local dest=$TMPDIR/destination
  local gate="my-gate"
  local passed="1234"

  local gate_ref=$(make_commit_to_file $repo "$gate/$passed")

  get_gate_at_ref "$repo" $gate $passed "$dest"

  test $(cat $dest/passed) = "$passed"
  test $(cat $dest/metadata) = "x"
}

run it_can_get_from_version