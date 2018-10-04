#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_get_from_version() {
  local repo=$(init_repo)
  local dest=$TMPDIR/destination
  local gate="my-gate"
  local passed="1234"

  get_gate_at_ref "$repo" $gate $passed "$dest"

  test $(cat $dest/.git/gate_passed) = "$passed"
}

run it_can_get_from_version