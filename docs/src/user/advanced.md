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

An optional command can be passed to run it directly in the container and return immediately:
```
bbx shell <command> [args...]
```

Examples:
```bash
bbx shell bash -c "find /usr/lib -name '*.so' | wc -l"
```

The container's BuildBox environment (`BB_PROJECT_DIR`, `BB_TARGET`, etc.) is available to the command. For shell constructs (pipes, redirects), pass them to an explicit shell as shown above.

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
