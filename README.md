# gate-resource

[![Build](https://github.com/meshcloud/gate-resource/actions/workflows/release.yml/badge.svg)](https://github.com/meshcloud/gate-resource/actions/workflows/release.yml)

A generic gate resource for Concourse CI.

Allows you to model quality gates and pipeline control flow.

This resource is backed by a Git repository and wraps [git-resource](https://github.com/concourse/git-resource).

A public container build of this repo is available at ghcr.io [meshcloud/gate-resource](https://github.com/meshcloud/gate-resource/pkgs/container/gate-resource).

> Contributors Welcome: This resource is new and hot off the press. We welcome your feedback and contributions!

## Example

To see an example pipeline using gate-resource, head over to [gate-resource-example](https://github.com/Meshcloud/gate-resource-example).

## Git Repository Structure

```text
.
├── my-gate
│   ├── 1
│   └── 2
└── my-autogate
    ├── a
    └── b.autogate
```

> note: The gate repository is currently append-only. Files are not expected to be deleted or cleaned.

The gate-resource supports two types of gates: simple-gates and auto-gates.

### Simple-gates

Each folder in the repository represents a gate. Files in each gate-folder represent items that successfully passed the gate. The files may be empty or contain any metadata that you whish to track. In the example above, `my-gate` is a simple-gate

### Auto-gates

Auto-gates are gates that automatically close depending on items passing through other gates. An auto-gate contains `.autoclose` items, which is a simple text file that contains dependant items, one on each line ("autoclose spec"). For example, `b.autoclose` depends on these two items passing through `my-gate`:

```b.autoclose
my-gate/2
my-gate/3
# metadata after this line
arbitrary content goes here
```

When all dependant items passed, the autoclose item closes and drops the `.autoclose` extension from its filename. Autoclose files can also contain additional metadata. To separate the autoclose spec from additional metadata, gate-resource looks for a line starting with `#` and stops interpreting any lines after this.

#### The "none" version

Unfortunately Concourse does not support emitting an empty set of versions from `out`. However, this is necessary for gate-resource as it may not find any autoclose items to close in a particular update. As a workaround, gate-resource emits the `none` version. `in` will no-op on encountering this version. 

Since concourse detects that the `none` version already exists after the first time it's generated, it will only trigger a single build when an auto-gate is used with `trigger: true`. You can detect that the `none` version was fetched  when no `passed` and `metadata` files were created by the `get` step (see below).

## Source Configuration

* `git`: *Required.* Configuration of the repository. Supports the following subset of [git-resource](https://github.com/concourse/git-resource) configuration options (review the link for descriptions)
  * *Required*: `uri`, `branch`, `private_key`
  * *Optional*: `git_config`, `short_ref_format`,
* `gate`: *Optional.* The gate to track.

## Behavior

### `check`: Check for changes to the gate

The repository is cloned (or pulled if already present), and any commits made to the specified `gate` from the given version on are checked for items passing through the gate.

> note: If you want to ensure the resource triggers for every item that passed the gate, use the resource with `version: every`

### `in`: Fetch an item that passed a gate

Outputs 2 files:

* `passed`: Contains the name of the item that passed the gate
* `metadata`: Contains the contents of whatever was in your gate item. This is
  useful for environment configuration settings or documenting approval workflows.

> note: the git repository cloned during `in` is a shallow clone and does not track an upstream branch.
> This is not a problem when using the `out` step to create or update gates.

### `out`: Pass an item through a gate

Performs one of the following actions to change the state of a gate.

#### Parameters

One of the following is required.

* `item_file`: Path to a file containing an item to pass through the gate. Wildcards are allowed, but should match only a single item. This file may also be a `.autogate` file.
* `update_autoclose`: Process pending autoclose items in the repository

> Note: Gate puts are idempotent. When putting a new gate item or `.autoclose` spec, the resource checks if a matching item already passed the gate. When this is the case, `out` will emit the version that previously produced this item.

#### Creating .autoclose items

`.autoclose` items can be put to the gate just like regular items. However, the version that gate-resource will emmit for this item may vary:

* when a matching target item (i.e. the filename without `.autoclose` extension) already
  exists, emits the version that produced this target item.
* when the `.autoclose` item is immediately closable (all dependent items alreday passed
  their gates), close the item and emit the version
* otherwise emit a `none` version (see above)

## Development

### Prerequisites

* docker is *required* - version 17.06.x is tested; earlier versions may also
  work.

### Running the tests

The tests have been embedded with the `Dockerfile`; ensuring that the testing
environment is consistent across any `docker` enabled platform. When the docker
image builds, the test are run inside the docker container, on failure they
will stop the build.

Run the tests with the following command:

```sh
docker build -t gate-resource .
```
