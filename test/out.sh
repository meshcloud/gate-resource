#!/bin/bash

set -e

source $(dirname $0)/helpers.sh

it_can_put_gate() {
  local repo1=$(init_repo)
  # cannot push to repo while it's checked out to a branch, so we switch to a different branch
  git -C $repo1 checkout refs/heads/master

  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local repo2=$src/gate-repo
  git clone $repo1 $repo2

  local gate="my-gate"
  local passed_file="gating-task/*"
  local passed="1234"
  mkdir -p $src/gating-task
  echo "arbitrary contents" > $src/gating-task/$passed

  put_gate $repo1 $src $gate $passed_file "gate-repo" | jq -e '
    .version == {"gate": "'$gate'", "passed": "'$passed'"}
  '

  # check that the gate file was written
  git -C $repo1 checkout master
  ls -la $repo1/$gate
  
  local expectedFile="$repo1/$gate/$passed"
  echo "testing $expectedFile"
  test -e $expectedFile
}

run it_can_put_gate