---
name: buildbox
description: Work on a BuildBox project, to build, test and deliver targets, manage packages and tools, and drive the project container with the bbx command. Use when the working directory is a BuildBox project (it contains a .bbx/ directory), or when the request mentions BuildBox, bbx, a target, a package or a tool.
---

# Working on a BuildBox project

BuildBox gives a project a reproducible build environment, running in one container per
project. Everything goes through the `bbx` command, from the project directory or any
subdirectory of it.

## Situate yourself first

| Command | Answers |
|---|---|
| `bbx env` | the `BB_*` variables: project, target, and their directories |
| `bbx target list` | the available targets, and which one is active |
| `bbx target info` | paths of the active target, whether it is cloned, testable, distributable |
| `bbx project info` | project revision, profile state |
| `bbx target pkg -v` | the target packages, their revision and build state |
| `bbx target tools` | the tools the target requires |

## Project layout

```
my_project/            project root, detected by the presence of .bbx/, NOT a git repository
├── .bbx/              profile: a git repository of its own, the versioned part of a project
├── state              active target name
├── cache/ tools/ trash/ tmp/    runtime
├── src/               package sources, shared between targets
└── <TARGET>/
    ├── src/           target sources, symlinked or copied from src/
    └── build/         installed files, this is $PREFIX
```

Git repositories to keep apart: the **profile** (`.bbx/`), and **each package and each tool**,
cloned by BuildBox under `src/`, `<TARGET>/src/` and `tools/`. A change belongs to the clone
it was made in, and the project root itself is not versioned.

## Rules that avoid most mistakes

- Run `bbx <command>` from the project, never a build tool of the project on the host: the
  toolchain, the variables and the tools only exist in the container. Use `bbx shell <cmd>`
  for anything else that needs that environment, and `bbx shell` alone for an interactive
  shell.
- Host only commands, which do not need a running container: `bbx init`, `bbx clone`,
  `bbx image`, `bbx instance`, `bbx stop`.
- A build can be long, and it writes its own log: `<TARGET>/target_build.log`, and
  `target_clone.log`, `tests.log`, `dist.log` for the other operations. A package keeps its
  own `build.log` in its source directory. Commands without an active target log into
  `.bbx/.logs/`.
- The active target drives everything, including the compilation settings, which come from
  its file `.bbx/target.<NAME>` only.
- Read `bbx <command> --help` before guessing options.

## Reference

Read the file matching the subject in `reference/`, generated from the BuildBox
documentation: `project.md`, `target.md`, `package.md`, `tool.md`, `container.md`,
`shell_plugin.md`, `advanced.md` (settings and pre-built targets), `utils.md`,
`install.md`, and `migration.md` (what to change when upgrading BuildBox).
