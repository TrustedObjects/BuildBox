# Environment variables

BuildBox uses several environment variables to work. These variables are kept
up-to-date by [local environment mechanism](api.md#local-environment), and are
influenced by active target settings.

::: warning
Do not write BuildBox environment variables directly, use [BuildBox API](api)
for that. This is the same for
[standard environment variables managed by BuildBox](#standard-variables-managed-by-buildbox).
:::

BuildBox environment variables can be used anywhere, for example for scripting
tests, packages distribution.

## BuildBox specific variables

It is possible to list only BuildBox environment variables and their values by
running:
```
bbx env
```

Here is a partial list of these variables and their meaning:
- `BB_TARGET`: active target name
- `BB_PROJECT_DIR`: active project base directory
- `BB_PROJECT_PROFILE_DIR`: active project profile directory (`.bbx/`)
- `BB_PROJECT_SRC_DIR`: active project sources directory
- `BB_TARGET_DIR`: active target base directory
- `BB_TARGET_SRC_DIR`: active target sources directory
- `BB_TARGET_BUILD_DIR`: active target build directory
- `BB_LAST_TARGET`: previous active target name
- `BB_TARGET_VAR_*`: target specific variable
- `BB_TOOLS_DIR`: tools local clones directory
- `BB_CACHE_DIR`: [BuildBox cache](api.md#file-cache)
- `BB_TRASH_KEEP_DAYS`: minimum days to keep data in BuildBox trash
- `BB_BUILD_JOBS`: concurrent build jobs number
- `BB_BINDIR`: BuildBox public and internal executables paths
- `BB_DIR`: BuildBox sources directory
- `BB_WORKDIR`: project profile directory path (`.bbx/`), bind-mounted at the same path on both host and container
- `BB_LAUNCHER_ID`: PID of the host-side `bbx` launcher process; used to locate the named pipes for the [`bb_host_send`](api.md) mechanism
- `BB_PREBUILT_USERNAME`: [pre-built target](/user/target.md#pre-built-targets) release user name for remote server
- `BB_PREBUILT_SERVER`: [pre-built target](/user/target.md#pre-built-targets) server address
- `BB_PREBUILT_PATH`: [pre-built target](/user/target.md#pre-built-targets) remote path
- `BB_PREBUILT_ONLY_TAGGED`: [pre-built target](/user/target.md#pre-built-targets) 1 to restrict pre-built target generation only to tagged projects, else 0
- `BB_LOCAL_ENV_LAST_*`: used for [local environment](api.md#local-environment) cache computation

There are also the following variables, not listed by `bbx env`:
- `CPU`
- `CPU_FAMILY`
- `CPU_DESCRIPTION` (do not rely on its value to condition code flow as it is a human-readable string subject to change)
- `CPUDEF`
- `CHOST`

## Standard variables managed by BuildBox

Moreover, BuildBox [local environment mechanism](api.md#local-environment) keeps
up-to-date the following environment variables:
- `PATH`
- `LD_LIBRARY_PATH`
- `PKG_CONFIG_PATH`
- `ACLOCAL_PATH`
- `XDG_DATA_DIRS`
- `CFLAGS`
- `LDFLAGS`
- `TMPDIR`, a temporary directory under the project profile directory
