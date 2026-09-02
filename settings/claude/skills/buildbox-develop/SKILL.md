---
name: buildbox-develop
description: Work on the BuildBox tool itself, its API library, its commands, its container images, its host launcher, its test suite or its documentation. Use when editing the BuildBox repository, meaning src/, docker/, settings/, tests/ or docs/ of BuildBox.
---

# Developing BuildBox

## Layout

| Path | Content |
|---|---|
| `src/_*.sh` | API library, sourced through `buildbox_utils.sh`, never executed |
| `src/commands/` | commands, public and internal, run inside the container |
| `docker/bin/bbx` | host launcher: one container per project, host only commands |
| `docker/` | container images, `buildbox` and its derived images |
| `settings/` | container ZSH configuration, host shell plugin, Claude Code skills |
| `tests/` | test framework, unit and functional cases, fixtures as git bundles |
| `docs/` | documentation site, and the generators of its generated pages |

## Conventions

- Every API function is prefixed `bb_`, declared with `bb_exportfn`, which also makes it
  available to child processes. A function calling a helper must have that helper exported
  too, otherwise it breaks when used from a child process.
- Subshell form `function name () ( ... )` when the function must not touch the caller
  environment.
- Everything must work in **bash and zsh**, including the tests.
- Nothing BuildBox opens or exports should survive into a project build: a descriptor, a
  variable or a process left behind turns into a stuck build later.

## Tests

```bash
./tests/run_tests                 # whole suite, bash
MODE=zsh ./tests/run_tests        # whole suite, zsh, required as well
./tests/run_tests test_bb_lock    # a single test, or a prefix
VERBOSE=1 ./tests/run_tests       # test output
```

Fixtures are rebuilt from `tests/bundles/` by `tests/repositories/setup.sh`, which never
resets an existing fixture: `rm -rf tests/repositories tests/workspace` before a run
reproduces the conditions of the continuous integration.

## Generated files, never edited by hand

| File | Generator |
|---|---|
| `docs/src/dev/api.md` | `docs/src/dev/generate_apidoc.sh`, from the `##` comments of `src/_*.sh` |
| `docs/src/parts/news.md` | `docs/src/dev/generate_news.sh`, from the `ChangeLog` |
| `settings/claude/skills/*/reference/` | `settings/claude/generate_reference.sh`, from `docs/src/` |
| `VERSION` | `make version`, from `git describe` |

## Reference

`reference/index.md`, `reference/developing.md`, `reference/container.md`,
`reference/shell.md`, plus the `CLAUDE.md` of the repository for the architecture.
