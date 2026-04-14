# Create new build modes

::: tip
Before reading this chapter, it is recommended to read the chapter related to
[BuildBox API development](developing.md).
:::

Be default, BuildBox comes with several supported build modes: `autotools`,
`make`, ...
But it is possible to develop new build modes which can then be used by
packages.

::: tip
Most of the time, developing a new build mode is not mandatory as the
[custom build mode](/user/package.md#custom) can easily cover most build needs.
:::

New build mode implementation is to be added in the `src/` directory of
BuildBox sources, and must be a `.sh` file with its name starting with `_build_`
suffix.

The following API has to be implemented in the build mode script (replace
MODENAME with the new build mode name):

## `bb_MODENAME_build()`

Build the package, and install in target if required.

Arguments:
- package sources directory
- build options

Return 0 on success.

## `bb_MODENAME_build_fast()`

Same as `bb_MODENAME_build()`, but faster (if possible), by skipping already
done things (build configuration steps for example).

## `bb_MODENAME_build()_clean`

Clean build generated files, but **do not** remove files installed in target.

Arguments:
- package sources directory

Return 0 on success.

## `bb_MODENAME_build()_stat_warning`

Get build warning count.

Arguments:
- package sources directory

Print number of warnings.

Return:
- 0 on success
- 1 if getting warning count is not supported

## `bb_MODENAME_build()_stat_installed`

Get target installed version of the package.

Arguments:
- package sources directory

Print installed version.

Return:
- 0 on success
- 1 if unknown

## `bb_MODENAME_build()_supports_sources_sharing`

Return 1 if the build mode supports packages sources sharing.
Sources can be shared if build doesn't alter sources directory, and if it can
be then shared by multiple targets.

## `bb_MODENAME_build()_get_build_dir`

Get package build directory.
This function implementation is optional. By default, BuildBox will return
package sources directory if this function is undefined.

Arguments:
- package sources directory

Print package build directory.

Return 0 on success.

