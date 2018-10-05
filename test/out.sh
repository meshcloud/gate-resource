#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_put_simplegate() {
  local upstreamRepo=$(init_repo)
  # cannot push to repo while it's checked out to a branch, so we switch to a different branch
  git -C $upstreamRepo checkout --quiet refs/heads/master

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local localRepo=$src/gate-repo
  git clone $upstreamRepo $localRepo

  local gate="my-gate"
  local item_file="gating-task/*"
  local passed="1234"
  mkdir -p $src/gating-task
  echo "arbitrary contents" > $src/gating-task/$passed

  result=$(put_gate $upstreamRepo $src $gate $item_file "gate-repo")
  echo "result: $result"
  echo "$result" | jq -e '
    .version == {"gate": "'$gate'", "passed": "'$passed'"}
  '

  # check that the gate file was written
  git -C $upstreamRepo checkout master
  ls -la $upstreamRepo/$gate
  
  local expectedFile="$upstreamRepo/$gate/$passed"
  echo "testing $expectedFile"
  test -e $expectedFile
}

it_can_put_autogate() {
  local upstreamRepo=$(init_repo)
  # cannot push to repo while it's checked out to a branch, so we switch to a different branch
  git -C $upstreamRepo checkout --quiet refs/heads/master

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local localRepo=$src/gate-repo
  git clone $upstreamRepo $localRepo

  local gate="auto-gate"
  local item_file="gating-task/*autogate"
  local item="1234.autogate"
  mkdir -p $src/gating-task
  echo "simple-gate/1" >> $src/gating-task/$item

  put_gate $upstreamRepo $src $gate $item_file "gate-repo" | jq -e '
    .version == {"gate": "'$gate'", "passed": "'$item'"}
  '

  # check that the gate file was written
  git -C $upstreamRepo checkout master
  ls -la $upstreamRepo/$gate
  
  local expectedFile="$upstreamRepo/$gate/$item"
  echo "testing $expectedFile"
  test -e $expectedFile
}

run it_can_put_simplegate
run it_can_put_autogate