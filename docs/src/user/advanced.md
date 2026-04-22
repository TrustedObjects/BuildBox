# Advanced features

## Settings

BuildBox settings defaults can be changed in `.bbx/custom_config` file at the project root.

Accepted options are:
- `BB_BUILD_JOBS`: set to `9` by default, it is the number of jobs to spawn when building packages
- `BB_TRASH_KEEP_DAYS`: set to `15` by default, it is the minimum time to keep files in the trash before automatically removing them
- `BB_DEBUG`: disabled by default, set to `1` to enable debug (very verbose in standard output)

There are also prebuilt target options which are detailed in [prebuilt target](target.md#pre-built-targets) section.

## Interactive shell

BuildBox provides an interactive ZSH shell for convenience, which can be opened with:
```
bbx shell
```

From this shell, all BuildBox commands are available without the `bbx` prefix:
```
target set myplatform
build my_package
```

The environment is refreshed before every command.

## Administration mode

Although it is possible to use `sudo` inside BuildBox, you also have an administration shell available.
It is helpful to configure the system inside the container or to add system packages.

To open an administration shell, run from the container:
```
sudo -i
```

::: danger
If adding package or changing configuration as administrator, you should discuss with your BuildBox maintainer to make these changes available in the future container image release ! Else, you will have an environment not synchronized with other developers working on the same projects as you.
:::
