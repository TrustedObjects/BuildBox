# Targets

A target stands for a particular hardware and software context, inside of a project.
Its purpose is to build a bunch of software component packages for a defined platform with defined options.
It also allows testing the produced deliveries.

BuildBox ensures that environment variables are always related to the active target. Paths are pointing to current target paths and to its needed tools.

Environment variables precedence respects the following rule:
tools (from the last to the first, from target tools list) > target > BuildBox > system.

## Target profile

Targets profiles are defined in project profile directory `.bbx/`, in files prefixed by `target.`.
Target profile file is available at `.bbx/target.<TARGET>`.

Target file accepted fields are:
- `PACKAGES` defines a file listing target packages (must be stored in project profile directory).
- `TOOLS` (optional) defines a file listing target required tools, and toolchains (must be stored in project profile directory).
- `TESTS` (optional) defines a [target test script](#target-test-and-delivery-scripts).
- `DIST` (optional) defines a [target delivery script](#target-test-and-delivery-scripts).
- `DESCRIPTION` (optional) short target description.
- `VAR_xxx` (optional) target variables (replace xxx with whatever you want)
- [build settings](#target-build-settings) (optional): `CPU`, `CPU_FAMILY`, `CPU_DESCRIPTION`, `CPUDEF`, `CHOST`, `CFLAGS` and `LDFLAGS`.

Every field is optional: a target file may define nothing at all, in which case
the target is built for the machine running BuildBox, with no specific flag.

You can define specific target variables, with `VAR_xxx` entries (replace xxx with whatever you want).
Target variables result in environment variables declaration when the target is active, named `BB_TARGET_VAR_xxx`.

Strings in target file must be escaped like this: `\\\"my string\\\"`.

`TOOLS` and `PACKAGES` files defines listing with an entry by line.
Listed entries references files in project profile `packages` sub-directory.
See [package list file](package.md#target-packages-list) to know how to write a `PACKAGES` file.
More details about tools and packages are in [packages](package.md) and [tools](tool.md) documentation.

Example of a target file:
```
CPU=x86
TOOLS=tools.prod
PACKAGES=packages.prod
TESTS=${BB_PROJECT_PROFILE_DIR}/tests.sh
DIST=${BB_PROJECT_PROFILE_DIR}/dist.sh
DESCRIPTION="My target description"
```

The target directory (if the target has been fetched) is `<TARGET>/` at the project root.
Built packages are installed in the target build directory, `<TARGET>/build`.

## Target build settings

BuildBox does not know any CPU nor any toolchain: the target file is the only
place where the target hardware specifics are described. BuildBox only takes
care of the mechanics, and exports what the target file defines to the
[build environment](/dev/envvars.md), so that packages build scripts, test and
delivery scripts can use it.

The following fields are accepted, all of them being optional:

| Field | Meaning | Default value |
|-------|---------|---------------|
| `CPU` | Target CPU name, freely chosen (it is also the name displayed by `bbx target list`) | `x86` |
| `CPU_FAMILY` | CPU family, to share code between several CPU of the same family | `CPU` value, uppercased |
| `CPUDEF` | CPU identifier, meant to be used as a C pre-processor definition | `CPU` value, uppercased |
| `CPU_DESCRIPTION` | Human readable CPU description | `CPU` value |
| `CHOST` | Toolchain host triplet, passed to `configure` scripts as `--host` for [autotools packages](package.md#autotools) | `x86_64-pc-linux-gnu` |
| `CFLAGS` | Compilation flags for the target | none |
| `LDFLAGS` | Link flags for the target | none |

When a field is left undefined (or defined empty), its default value applies.
Defaults describe a native build for the machine running BuildBox, which is why
a target file defining nothing at all builds for the host.

For `CPU_FAMILY` and `CPUDEF` defaults, uppercasing the `CPU` value also
replaces every character which is neither a letter nor a digit by an
underscore, so that the result can be used as a C pre-processor definition: for
example `CPU=cortex-m33` gives `CORTEX_M33`.

::: tip
Fields are plain shell assignments, evaluated in the order they appear in the
file, so a field can reference a previously defined one, for example
`CFLAGS="-mcpu=${CPU} -mthumb"`.
:::

`CFLAGS` and `LDFLAGS` given here are the target specific flags only: BuildBox
completes them with the target build directory and the target tools include and
library paths. Do not reference these paths in the target file.

Example of a target file for an ARM Cortex-M33 firmware, built with a bare
metal toolchain provided as a [tool](tool.md):
```
CPU=cortex-m33
CPU_FAMILY=ARM
CPU_DESCRIPTION="Cortex-M33 with security extensions"
CPUDEF=CORTEX_M33
CHOST=arm-none-eabi
CFLAGS="-mcpu=cortex-m33 -mthumb -mfloat-abi=soft -mcmse -mgeneral-regs-only"
LDFLAGS="-specs=nosys.specs -specs=nano.specs"
TOOLS=tools.prod
PACKAGES=packages.prod
DESCRIPTION="Secure firmware"
```

::: warning
BuildBox 2.0.2 and older had built-in flags for a fixed list of CPU. Projects
relying on them must declare these flags in their target files: see
[version migrations](migration.md#target-build-settings-are-no-longer-built-in).
:::

Dealing with targets is done through the `target` command, detailed below.

## List targets

To list current project available targets, use:

```
bbx target list
```

## Set target

To switch current project target, use:
```
bbx target set TARGET
```

Set current project `TARGET`. Following commands are going to concern this set target.

## Target information

To display target information:
```
bbx target info [TARGET]
```

This command displays target information (defaults current target if `TARGET` is not specified).
Displayed information:

| Name | Description |
|------|-------------|
| Target | Target name |
| Path | Location of the target directory in the project |
| Profile path | Target profile file path |
| Testable | Indicates if the target has a self-test script available |
| Distributable | Indicates if the target has a distribution script available |
| Is cloned | Tells whether the target is cloned, `yes` if all packages are cloned, `partially` if some of them are cloned, else `no` |

## Fetch target

The following command is used to fetch all target required tools and packages sources:
```
bbx target clone
```

In case of error, logs can be accessed from `<TARGET>/target_clone.log`.

## Build target

To build target packages:
```
bbx target build [-v] [-c|--continue]
```

Install target required tools, and build (and install) target packages.
Packages are automatically fetched if not done yet.

The `-v` option enables verbose mode to show all build logs.

The `-c` or `--continue` option allows to retry a build from where it failed.

In case of error, logs can be accessed from `<TARGET>/target_build.log`.

## Build target (fast)

As `target build`, it is possible to use:
```
bbx target fastbuild [-v] [-c|--continue]
```

This command does not do package configuration step, it is assumed packages sources are already configured. This is why it is named "fast".

See [Build target](#build-target) for more details about options.

In case of error, logs can be accessed from `<TARGET>/target_fastbuild.log`.

## Test target

To run target tests, use:
```
bbx target test [-q | OPTIONS]
```

A log file is used for test output, stored in `tests.log` in target directory.

The `-q` option enables quiet mode: tests logs are only written to log file.

A target self-test script must be defined in the [target profile file](#target-profile).
`OPTIONS` are passed to the target test script.

## Make target delivery

To make a deliverable for the current target, use:
```
bbx target dist [OPTIONS]
```

This command generates target deliverables.
A target distribution script must be defined in the target profile file.
`OPTIONS` are passed to the target dist script.

A log file is used for distribution output, stored in `dist.log` in target directory.

## Clean target built files

To clean built files, run:
```
bbx target clean
```

Cleans target by removing built files in each packages.
The target build directory is also removed.

## Clean all target files

To clean all target files:
```
bbx target mrproper
```

This command wipes target by removing sources and built files in each packages.
The target build directory is also removed. Sources are sent to BuildBox trash, and kept for a while.

::: warning
For packages using [shared sources](package.md#package-sources), sources are also removed from project (this affects other targets).
:::

## List target packages

To list target packages, use:
```
bbx target pkg [-m] [-v]
```

It displays target packages information.

The `-m` option displays only packages having locally modified sources. It helps to identify uncommitted changes.

The `-v` option enables verbose mode, which displays package details.

## List target tools

To list target tools, use:
```
bbx target tools
```

Current target required tools are listed with their details.

## Pre-built targets

Pre-built targets are built files of specific project revision targets, whose purpose is to avoid spending time building targets locally.

Settings before using pre-built targets can be defined in a
[`config` file](advanced.md#settings): `.bbx/config` for a single project,
`~/.config/buildbox/config` for all your projects, or `/etc/buildbox/config`
for all the users of the machine:
- `BB_PREBUILT_SERVER`: pre-built targets SSH server
- `BB_PREBUILT_USERNAME`: username to connect to pre-built targets server
- `BB_PREBUILT_PATH`: pre-built targets directory on server

Credentials such as `BB_PREBUILT_USERNAME` are usually set in the user file,
while the server and path are shared by the whole team in the project file. On
a build machine, the system file is a good place for the server settings.

Pre-built targets can only be created for tagged projects revisions.

To get a prebuilt target from server, you have to [fetch the target](#fetch-target) using `bbx target clone -p`.

## Target test and delivery scripts

In the target file, you can define a test script with the `TESTS` field.
The same way, you can define a delivery script with the `DIST` field.
These scripts must be executable bash scripts which can be either located in the project profile, provided by a package or by a tool.

These scripts **should not use BuildBox user commands**, and should rely on [BuildBox API](/dev/api.md) instead.

These scripts **must** catch and return any error as a non-zero shell error code. You can use `set -e` for that.

Also, these scripts should carefully clean up any temporary resources created on exit.
Produced test report or delivery archive may be stored in target directory.

Read [how to develop scripts using BuildBox](/dev/scripting.md) for more details.
