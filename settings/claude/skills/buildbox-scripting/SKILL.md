---
name: buildbox-scripting
description: Write or fix a script run by BuildBox, such as a target test or delivery script (TESTS, DIST), a package build script (build.sh, build_fast.sh, clean.sh), or a tool load and unload script. Use when editing these scripts, or when using bb_* API functions or BB_* environment variables.
---

# Scripting inside BuildBox

Scripts run by BuildBox get their context from the environment BuildBox sets, and talk to
BuildBox through its API.

## Rules

- Source the API when the script needs it: `source buildbox_utils.sh`. It detects the project
  from the working directory and exports every `BB_*` variable.
- **Never parse the output of a `bbx` command**: that output is meant for humans and is not
  stable. Use the API functions instead, they are the stable interface.
- Return a non-zero status on error, `set -e` helps. BuildBox reports a failure only if the
  script says so.
- Clean up what the script creates, on every exit path: `bb_add_exit_action` registers an
  action run when the process ends.
- Do not write the variables BuildBox manages (`PATH`, `CFLAGS`, `PREFIX`, `CHOST`, ...): they
  are rebuilt from the active target and its tools. Add a setting to the target file instead.
- A service or a daemon needed by a build belongs in a **tool** (`load.sh` and `unload.sh`
  hooks), not in a package build script: a tool has a lifecycle managed by BuildBox, a build
  script does not.

## Where things come from

| Need | Source |
|---|---|
| project and target paths | `BB_PROJECT_DIR`, `BB_TARGET_DIR`, `BB_TARGET_SRC_DIR`, `BB_TARGET_BUILD_DIR` |
| project specific values | `BB_TARGET_VAR_*`, defined as `VAR_*` in the target file |
| compilation settings | `CPU`, `CPU_FAMILY`, `CPUDEF`, `CHOST`, `CFLAGS`, `LDFLAGS`, from the target file |
| installation prefix | `PREFIX`, which is the target `build/` directory |
| a package or tool path | `bb_get_package_src_dir`, `bb_get_package_build_dir`, `bb_get_tools` |

## Reference

- `reference/scripting.md`: how to write test and delivery scripts.
- `reference/envvars.md`: every variable, and which ones BuildBox keeps up to date.
- `reference/build_modes.md`: the build modes and the scripts each one expects.
- `reference/api.md`: the complete API, function by function, with parameters and returns.
