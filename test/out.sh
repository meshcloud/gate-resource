#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_put_item_to_simple_gate() {
  local upstreamRepo=$(init_repo)
  local initial_ref=$(make_commit $upstreamRepo)
  upstream_repo_allow_push $upstreamRepo

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local localRepo=$src/gate-repo
  git clone $upstreamRepo $localRepo

  local gate="my-gate"
  local item_file="gating-task/*"
  local item="1234"
  mkdir -p $src/gating-task
  echo "arbitrary contents" > $src/gating-task/$item

  result=$(put_gate_item_file $upstreamRepo $src $gate $item_file)

  git -C $upstreamRepo checkout master
  local pushed_ref="$(git -C $upstreamRepo rev-parse HEAD)"

  # check a new commit was created
  test ! $pushed_ref == $initial_ref
  # check output
  echo "$result" | jq -e '
    .version == { "ref": "'$pushed_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "'$item'")
  '
  # check that the gate file was written
  test -e "$upstreamRepo/$gate/$item"
}

it_can_put_item_to_autoclose_gate() {
  local upstreamRepo=$(init_repo)
  local initial_ref=$(make_commit $upstreamRepo)
  upstream_repo_allow_push $upstreamRepo

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local localRepo=$src/gate-repo
  git clone $upstreamRepo $localRepo

  local gate="auto-gate"
  local item_file="gating-task/*.autoclose"
  local item="1234.autoclose"
  mkdir -p $src/gating-task
  echo "simple-gate/1" >> $src/gating-task/$item

  result=$(put_gate_item_file $upstreamRepo $src $gate $item_file)

  git -C $upstreamRepo checkout master
  local pushed_ref="$(git -C $upstreamRepo rev-parse HEAD)"

  # check a new commit was created
  test ! $pushed_ref == $initial_ref
  # check output
  echo "$result" | jq -e '
    .version == { "ref": "'$pushed_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "'$item'")
  '
  # check that the gate file was written
  test -e "$upstreamRepo/$gate/$item"
}

update_autoclose_gate_with_no_closable_items_returns_head() {
  local gate="auto-gate"

  local upstreamRepo=$(init_repo)
  mkdir -p "$upstreamRepo/$gate"
  echo "simple-gate/1" >> "$upstreamRepo/$gate/1.autoclose"
  local head_ref=$(make_commit_with_all_changes $upstreamRepo)
  
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local localRepo=$src/gate-repo
  git clone $upstreamRepo $localRepo

  upstream_repo_allow_push $upstreamRepo
  result=$(put_gate_update_autoclose $upstreamRepo $src $gate)
  
  upstream_repo_allow_asserts $upstreamRepo
  local pushed_ref="$(git -C $upstreamRepo rev-parse HEAD)"

  # check no new commit was created
  test $pushed_ref == $head_ref
  # check output
  echo "$result" | jq -e '
    .version == { "ref": "'$head_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "'1.autoclose'")
  '
}

run it_can_put_item_to_simple_gate
run it_can_put_item_to_autoclose_gate
run update_autoclose_gate_with_no_closable_items_returns_head