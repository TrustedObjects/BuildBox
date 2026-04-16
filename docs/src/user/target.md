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
- `CPU` defines the target CPU to build for.
- `TOOLS` (optional) defines a file listing target required tools, and toolchains (must be stored in project profile directory).
- `PACKAGES` defines a file listing target packages (must be stored in project profile directory).
- `TESTS` (optional) defines a [target test script](#target-test-and-delivery-scripts).
- `DIST` (optional) defines a [target delivery script](#target-test-and-delivery-scripts).
- `DESCRIPTION` (optional) short target description.
- `VAR_xxx` (optional) target variables (replace xxx with whatever you want)

Accepted values for `CPU`: `x86`, `arm-linux`, `cortex-m0`, `cortex-m3`, `cortex-m4`, `cortex-m7`, `cortex-m23`, `cortex-m33`, `cortex-m35P`, `cortex-m55`, `lx6`

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

Settings before using pre-built targets can be defined in `.bbx/custom_config`:
- `BB_PREBUILT_SERVER`: pre-built targets SSH server
- `BB_PREBUILT_USERNAME`: username to connect to pre-built targets server
- `BB_PREBUILT_PATH`: pre-built targets directory on server

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
