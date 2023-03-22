# Release Notes
## 2.0.0

- no changes on the code itself. We move the publishment from dockehub to ghcr..

## 2.0.0-beta1

- Use a custom `in` script instead of the script provided by the embedded [git-resource](https://github.com/concourse/git-resource).
  This allows us to efficiently fetch shallow clones at exactly a specified
  revision without incurring needless `git fetch --deepen` roundtrips.

Note: this release can break configuration for the `get` step in your pipelines as
it removes configuration options inherited from `git-resource` that don't make
sense in the context of gate-resource anymore. This helps to achieve better `get` performance and is critical for large gate repository.

Please review the [README](./README.md) for updated configuration options.

## 1.1.1

- Patch an issue with shallow-clones not fetching at the correct depth in git-resource.
  See https://github.com/concourse/git-resource/pull/316 for more details.

## 1.1.0

- Updates git-resource to 1.7.0
- Use shallow clones for cloning the gate repository. This should increase performance.

## 1.0.0

Initial Release.
