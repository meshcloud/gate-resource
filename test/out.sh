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

it_can_put_existing_item_to_simple_gate_returns_existing_ref() {
  local repo=$(init_repo)
  local src=$TMPDIR/src
  local gate="my-gate"
  local item="1234"
  local other_item="abcd"

  local existing_ref=$(make_commit_to_file $repo "$gate/$item")
  local other_ref=$(make_commit_to_file $repo "$gate/$other_item")
  
  local item_file="gating-task/*"
  mkdir -p "$src/gating-task"
  echo "arbitrary contents" > "$src/gating-task/$item"

  result=$(put_gate_item_file $repo $src $gate $item_file)

  test ! $existing_ref == $other_ref
  # check output points to existing ref
  echo "$result" | jq -e '
    .version == { "ref": "'$existing_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "'$item'")
  '
}

it_can_put_autoclose_item_to_autoclose_gate() {
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
    .version == { "ref": "none" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "none")
  '
  # check that the gate file was written
  test -e "$upstreamRepo/$gate/$item"
}

it_can_put_autoclose_item_that_is_closable_to_autoclose_gate() {
  local upstreamRepo=$(init_repo)
  local simple_gate="simple-gate"
  local simple_item="1"
  local simple_ref=$(make_commit_to_file "$upstreamRepo" "$simple_gate/$simple_item")

  upstream_repo_allow_push $upstreamRepo

  local src=$(mktemp -d "$TMPDIR/put-src.XXXXXX")
  local localRepo=$src/gate-repo
  git clone "$upstreamRepo" "$localRepo"

  local gate="auto-gate"
  local item_file="gating-task/*.autoclose"
  local closed_item="1234"
  local closable_item="$closed_item.autoclose"
  mkdir -p "$src/gating-task"
  echo "$simple_gate/$simple_item" >> "$src/gating-task/$closable_item"

  result=$(put_gate_item_file $upstreamRepo $src $gate $item_file)

  git -C $upstreamRepo checkout master
  local closable_ref="$(git -C $upstreamRepo rev-parse HEAD~1)"
  local closed_ref="$(git -C $upstreamRepo rev-parse HEAD)"

  set -x
  # checknew commits were created
  test ! "$closable_ref" == "$simple_ref"
  test ! "$closed_ref" == "$closable_ref"

  # check output
  echo "$result" | jq -e '
    .version == { "ref": "'$closed_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "'$closed_item'")
  '
  # check that the gate file was written
  test -e "$upstreamRepo/$gate/$closed_item"
}

it_can_put_existing_item_to_autoclose_gate_returns_existing_ref() {
  local repo=$(init_repo)
  local src=$TMPDIR/src
  local gate="my-gate"
  local item="1234"
  local other_item="abcd"

  # there already exists a passed item for which we want to emit an autoclose spec
  local existing_ref=$(make_commit_to_file $repo "$gate/$item")
  local other_ref=$(make_commit_to_file $repo "$gate/$other_item")

  local item_file="gating-task/*"
  mkdir -p "$src/gating-task"
  echo "arbitrary contents" > "$src/gating-task/$item.autoclose"

  result=$(put_gate_item_file $repo $src $gate $item_file)

  test ! "$existing_ref" == "$other_ref"
  # check output points to existing ref
  echo "$result" | jq -e '
    .version == { "ref": "'$existing_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "'$item'")
  '
}

update_autoclose_gate_with_no_closable_items_returns_none() {
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
    .version == { "ref": "none" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "none")
  '
}

update_autoclose_gate_with_empty_gate_returns_none() {
  local gate="auto-gate"

  local upstreamRepo=$(init_repo)
  local head_ref=$(make_commit_to_file $upstreamRepo "my-gate/1")
    
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
    .version == { "ref": "none" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "none")
  '
}

update_autoclose_gate_ignores_metadata_after_hash() {
  local gate="auto-gate"

  local upstreamRepo=$(init_repo)
  mkdir -p "$upstreamRepo/$gate"
  echo "" >> "$upstreamRepo/$gate/1.autoclose"
  echo "#" >> "$upstreamRepo/$gate/1.autoclose"
  echo "some metadata" >> "$upstreamRepo/$gate/1.autoclose"
  local head_ref=$(make_commit_with_all_changes $upstreamRepo)
  
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local localRepo=$src/gate-repo
  git clone $upstreamRepo $localRepo

  upstream_repo_allow_push $upstreamRepo
  result=$(put_gate_update_autoclose $upstreamRepo $src $gate)
  
  upstream_repo_allow_asserts $upstreamRepo
  local pushed_ref="$(git -C $upstreamRepo rev-parse HEAD)"

  # check no new commit was created
  test ! $pushed_ref == $head_ref
  # check output
  echo "$result" | jq -e '
    .version == { "ref": "'$pushed_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "1")
  '
}

update_autoclose_gate_with_closable_items_returns_first_closed() {
  local gate="auto-gate"

  local upstreamRepo=$(init_repo)
  mkdir -p "$upstreamRepo/$gate"
  mkdir -p "$upstreamRepo/simple-gate"
  echo "simple-gate/a" >> "$upstreamRepo/$gate/1.autoclose"
  echo "simple-gate/a" >> "$upstreamRepo/$gate/2.autoclose"
  echo "x" >> "$upstreamRepo/simple-gate/a"
  local head_ref=$(make_commit_with_all_changes $upstreamRepo)
  
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local localRepo=$src/gate-repo
  git clone $upstreamRepo $localRepo

  upstream_repo_allow_push $upstreamRepo
  result=$(put_gate_update_autoclose $upstreamRepo $src $gate)
  
  upstream_repo_allow_asserts $upstreamRepo
  local pushed_ref="$(git -C $upstreamRepo rev-parse HEAD~1)" # 2 items were closed

  # check new commit was created
  test ! $pushed_ref == $head_ref
  # check output
  echo "$result" | jq -e '
    .version == { "ref": "'$pushed_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "1")
  '
}

update_autoclose_gate_with_closable_items_retries_using_rebase_on_conflicts() {
  local gate="auto-gate"

  local upstreamRepo=$(init_repo)
  mkdir -p "$upstreamRepo/$gate"
  mkdir -p "$upstreamRepo/simple-gate"
  echo "simple-gate/a" >> "$upstreamRepo/$gate/1.autoclose"
  echo "simple-gate/b" >> "$upstreamRepo/$gate/2.autoclose"
  echo "x" >> "$upstreamRepo/simple-gate/a"
  local upstream_initial_ref=$(make_commit_with_all_changes $upstreamRepo)
  
  local src=$(mktemp -d $TMPDIR/put-src.XXXXXX)
  local localRepo=$src/gate-repo
  git clone $upstreamRepo $localRepo

  # make a change to upstream, local has to rebase before pushing
  # now two gates are autoclosable
  echo "x" >> "$upstreamRepo/simple-gate/b"
  local upstream_rebase_ref=$(make_commit_with_all_changes $upstreamRepo)

  echo ""
  echo "bumped upstream $upstream_initial_ref -> $upstream_rebase_ref"
  echo "" 

  upstream_repo_allow_push $upstreamRepo
  result=$(put_gate_update_autoclose_rebase $upstreamRepo $src $gate)
  
  upstream_repo_allow_asserts $upstreamRepo
  local rebased_from_ref="$(git -C $upstreamRepo rev-parse HEAD~2)" 
  local first_closed_ref="$(git -C $upstreamRepo rev-parse HEAD~1)" 
  
  # check new commit was created
  test ! $upstream_initial_ref == $upstream_rebase_ref 
  test $rebased_from_ref == $upstream_rebase_ref 
  # check output
  echo "$result" | jq -e '
    .version == { "ref": "'$first_closed_ref'" }
    and (.metadata | .[] | select(.name == "gate") | .value == "'$gate'")
    and (.metadata | .[] | select(.name == "passed") | .value == "1")
  '
}

run it_can_put_item_to_simple_gate
run it_can_put_existing_item_to_simple_gate_returns_existing_ref
run it_can_put_autoclose_item_to_autoclose_gate
run it_can_put_autoclose_item_that_is_closable_to_autoclose_gate
run it_can_put_existing_item_to_autoclose_gate_returns_existing_ref
run update_autoclose_gate_with_no_closable_items_returns_none
run update_autoclose_gate_ignores_metadata_after_hash
run update_autoclose_gate_with_empty_gate_returns_none
run update_autoclose_gate_with_closable_items_returns_first_closed
run update_autoclose_gate_with_closable_items_retries_using_rebase_on_conflicts