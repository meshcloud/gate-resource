# gate-resource

A generic gate resource for Concourse CI.

Allows you to model quality gates and pipeline control flow.

This resource is backed by a Git repository and wraps [git-resource](https://github.com/concourse/git-resource).

> Contributors Welcome: This resource is new and hot off the press. We welcome your feedback and contributions!

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

Auto-gates are gates that automatically close depending on items passing through other gates. A `.autogate` is a simple text file that contains dependant items, one on each line. For example, `b.autogate` depends on these two items passing through `my-gate`:

```b.autogate
my-gate/2
my-gate/3
```

When all dependant items passed, the autogate closes and drops the `.autogate` extension from its filename.

## Source Configuration

* `git`: *Required.* Configuration of the repository. See [git-resource](https://github.com/concourse/git-resource) for options.
  * **note:** the `paths` and `ignore_path` parameters are not supported

* `gate`: *Optional.* The gate to track.

## Behavior

### `check`: Check for changes to the gate

The repository is cloned (or pulled if already present), and any commits made to the specified `gate` from the given version on are checked for items passing through the gate.

> note:  Check currently only returns the latest item that passed a gate (i.e. it may miss intermediate passes).

The version returned to concourse looks like this:

```json
{ "gate": "my-gate", "passed": "1234" }
```

### `in`: Fetch an item that passed a gate

Outputs 2 files:

* `passed`: Contains the name of the item that passed the gate
* `metadata`: Contains the contents of whatever was in your gate item. This is
  useful for environment configuration settings or documenting approval workflows.

### `out`: Pass an item through a gate

Performs one of the following actions to change the state of the pool.

#### Parameters

One of the following is required.

* `item_file`: Path to a file containing an item to pass through the gate. Wildcards are allowed, but should match only a single item. This file may also be a `.autogate` file.
* `update_autoclose`: Process pending autoclose items in the repository

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

## Known Issues

The resource has the following known issues (mostly because they have not been implemented yet):

* `check` will always fetch HEAD and simply emit the latest passed gate. This may cause a pipeline to miss items that passed a gate. Instead, it should probably emit all the versions that have changed in between the last check and the current check. This would make it possible to use the resource with `version: every` and trigger for every item passing a gate.
* as
