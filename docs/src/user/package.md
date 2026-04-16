# Packages

Packages are pieces of software components.
Usually, packages consist of sources, but BuildBox also supports prebuilt packages made up of binary files.
They are collected from Git repositories, or compressed archives, and represented by a package file.
A package is built and installed in the targets requiring it, and can be shared across different targets,
projects and even receive different built options according your needs.

Packages are all represented by files in project `.bbx/packages` sub-directory.

## Target packages list

Needed Packages are specified on a per-target basis through a packages listing file, identified by `PACKAGES` in target profile.
In this file, one package can be specified per line, optionally with their build options.
Referenced packages are named like packages in project profile `.bbx/packages` sub-directory.

You can use blank lines, as well as put comments by simply starting your line with `#`.

Packages stored in SCM can have a generic file in project `.bbx/packages` sub-directory, named as the package.
Then, in target packages listing file, a revision can be defined prefixed by `@` sign. It can be a tag, a branch, or a changeset to checkout when the package is cloned. Alternatively, revision can be prefixed by `-`, but only for numeric values separated by dots `.`.
Generic packages files should point to the main branch by default.

Packages also accept build options and parameters in packages listing file, appearing after package name and a colon `:` sign.

BuildBox environment variables and target variables can be used in packages listing file.

Example of target package listing file:
```
# Simply the package1 taken its default branch (which is specified in the package's file)
package1

# Package2 will be checked-out on tag or branch 1.2.3
package2@1.2.3

# Package3 at tag or on branch 1.0
# It will be configured with `--enable-option1 --disable-option2 param=value`
package3@1.0: +option1 -option2 param=value

# Package4 at tag 2.0
# It will be configured with `param=${BB_TARGET}`
package4-2.0: target=${BB_TARGET}

# Package5 its default branch
# It will be configured with `param=${BB_TARGET_VAR_MYVAR}`
package5: param=${BB_TARGET_VAR_MYVAR}
```

To integrate a package to an existing target, edit its packages list file, and insert the new package entry.
Then, you can [fetch](target.md#fetch-target) or [build](target.md#build-target) the target, or [fetch](#fetch-package) or [build](#build-package) the new package itself.

When this integration is validated, don't forget to commit the project profile.

## Package file

Packages files are stored in project profile `.bbx/packages` sub-directory.
The package file describes the package (where to find it, how to build it...), it is formatted with one `KEY=VALUE` per line.

Fields to be used in packages files are:
- `SRC_PROTO`: protocol to get package sources
- `SRC_URI`: location where sources are stored
- `SRC_REVISION`: package revision identifier
- `SRC_BUILD`: sources build mode
- `SRC_CONFIG`: default build parameters
- `SRC_SUPPORTS_SHARING` (optional): set to 1 if packages supports sources sharing, 0 otherwise (see [package sources](#package-sources))

Supported `SRC_PROTO` are:
- `git`, then `SRC_REVISION` is a branch, a tag, or a changeset
- `http`, then `SRC_REVISION` is SHA256 digest of the archive

Supported `SRC_BUILD` modes are detailed in [build modes](#packages-build-modes) section.

## Package sources

Sources are fetched in `src/` at the project root.
Package sources directory in the target after package fetch are at `<TARGET>/src/<PACKAGE>`.

Sources may be shared between the project targets, according to the used build mode.
Indeed, some build modes are supporting sources sharing, other build modes do not, see [build modes](#packages-build-modes).

It is possible to ignore build mode sources sharing support status by defining in package if its sources can be shared or not.
For packages using build modes supporting shared sources, sources directory is symlinked into targets sources directory, else it is copied.

To ease package sources access from scripts, a symlink `<TARGET>/src/<PACKAGE_NAME>.sources` is created.
`PACKAGE_NAME` only represents the name of the package, without revision suffix. The link is pointing to the package version used by the target.

## Packages build modes

Accepted values for `SRC_BUILD` field in packages files are:
- `autotools`
- `make`
- `custom`
- `prebuilt`

### Autotools

This build mode is doing standard `autoreconf`, `configure`, `make` and `make install` calls.
Calls to `make clean` can also be performed.

Packages `SRC_CONFIG` field, or packages options in targets packages listing file, accept a simplified syntax:
- to enable an option, prefix it with "+",
- to disable an option use "-".

For example, `+option1` means `--enable-option1`.

Used build directory is at `<TARGET>/src/<PACKAGE>.build`.

This mode supports sources sharing.

### Make

This build mode is doing `make` and `make install` calls.
Calls to `make clean` can also be performed.

### Custom

For this case, package maintainer has to provide the following scripts at the root of the package sources directory:
- `build.sh`: cleanup, build and install the built files into `$PREFIX`
- `build_fast.sh` (optional): fast build mode (no cleanup, no configuration), if not present `build.sh` is used instead
- `clean.sh`: clean built files (do not uninstall)
- `warning_count.sh` (optional) prints number of build warnings

These scripts have to be executable.

The working dir of these scripts is set to the package sources directory.

### Prebuilt

This mode supposes package only contains binary files, and no action is performed to build anything.
The package files tree is expected to be structured as follows (all entries are optional):
- bin
- sbin
- lib
  - pkgconfig
  - python/site-packages
- share
  - pkgconfig
  - aclocal
- include

This mode supports sources sharing.

## Get package information

The following command can be used to get package information:
```
bbx pkg [-v] <FILTER> [FILTER]...
```

It gets information about packages having their name matching `FILTER` into the current target.
Packages must be referenced in the target packages file.
See [filtering packages](#filters-in-packages-management-commands) for more information about filter.

`-v` option enables verbose mode, displaying all package details:

| Name | Description |
|------|-------------|
| Revision | Package revision, branch or tag |
| Options | Package build options (defined by package itself or by target) |
| build mode | Tool used to build the package, see [packages build modes](#packages-build-modes) |
| Path | Package file path in project profile packages sub-directory |
| Sources | Package sources location (remote, local) |

## Fetch package

To fetch some of target packages sources:
```
bbx fetch <FILTER> [FILTER]...
```

It fetches packages having their name matching `FILTER` into the current target.
See [filtering packages](#filters-in-packages-management-commands) for more information about filter.

Sources may be shared between the project targets, according to the used build mode (see [package sources](#package-sources)).

Packages must be referenced in the target packages file.

## Build package

To build some of target packages, use:
```
bbx build <FILTER> [FILTER]...
```

It builds packages having their name matching `FILTER` into the current target.
See [filtering packages](#filters-in-packages-management-commands) for more information about filter.

Fetching is performed before if needed.

The build process and built files location depends on [packages build mode](#packages-build-modes).

## Build package (fast)

To build some of target packages faster, use:

```
bbx fastbuild <FILTER> [FILTER]...
```

It builds packages having their name matching `FILTER` into the current target, faster because it does not do package configuration step, it is assumed packages sources are already configured.
See [filtering packages](#filters-in-packages-management-commands) for more information about filter.

## Clean package built files

To clean package built files:
```
bbx clean <FILTER> [FILTER]...
```

Clean packages having their name matching `FILTER` into the current target.
See [filtering packages](#filters-in-packages-management-commands) for more information about filter.

Packages built files are removed, but files installed by these packages in target build directory are not affected.

## Wipe package

To wipe package:
```
bbx mrproper <FILTER> [FILTER]...
```

It wipes packages having their name matching `FILTER` into the current target.
See [filtering packages](#filters-in-packages-management-commands) for more information about filter.

Remove packages, including their sources (which are moved to trash), and built files, files installed by these packages in target build directory are not affected.

::: warning
For packages using [shared sources](#package-sources), sources are also removed from project (this affects other targets).
:::

## Filters in packages management commands

In packages management commands, filter is used to match packages if it is
included in their name, it can be full or partial package name.

In most of packages commands, the `FILTER` parameter can be a regular expression.
So for example, if you have the following packages in your target:
- `my_package`
- `package`
- `package_test`

then you can consider only `package` by using `^package$` as filter.

## Create a new package

To create a new package, you need to have its sources stored somewhere remotely (Git, HTTP archive).
Then, you have to create the BuildBox package file. Go to the project profile packages sub-directory:
```
cd .bbx/packages
```

Packages are usually all under the `master` branch of packages sub-module:
```
git fetch
git pull origin master
```

From there, you can create the new [package file](#package-file) and update [targets packages lists](#target-packages-list).

For packages using Git, it is possible to create a generic package file (without version) pointing to the main branch.
Then, in [targets packages lists](#target-packages-list), BuildBox can dynamically look for the specified version instead of default branch.
This is not possible for packages stored as archives on an HTTP server, for those the package file **must** include the version in their name.

Don't forget to test the fetch and build of the package, and you can commit your changes on the packages sub-module:
```
cd .bbx/packages
git add your_package_file
git commit -m"your message"
git push origin master
```

Go back to the project root, and commit the new changeset of the packages sub-module, and the updated targets.

## Commit changes on a package

If you made changes to a package sources, start by going to the package sources directory under `<TARGET>/src/<PACKAGE>`.

If the package is using Git, just commit your changes as usual, and create a new tag.

If the package is using HTTP, you have to create a new archive with the package version in its name, and send it to the HTTP server.
From project packages sub-module, copy the previous package file to create the new one, and update at least the `SRC_URI` and `SRC_REVISION` (SHA256 of the archive) fields.

From [targets packages lists](#target-packages-list), update entries to reference the new package revision.

::: tip
You can identify locally modified packages by running `bbx target pkg -m`.
:::
