# Advanced features

## Settings

BuildBox settings defaults can be changed in `config` files. Three of them are
read, in this order:
1. `/etc/buildbox/config`: system settings, shared by all the users of the machine
2. `~/.config/buildbox/config`: user settings, shared by all your projects
   (`$XDG_CONFIG_HOME/buildbox/config` when `XDG_CONFIG_HOME` is set)
3. `.bbx/config`: project settings, versioned with the project profile

Each file overrides the previous ones, and all of them override BuildBox
defaults. A setting defined in a file and not redefined by a higher priority
one is kept.

A `config` file is a shell fragment only made of variable assignments, one per
line:
```bash
BB_BUILD_JOBS=16
BB_PREBUILT_SERVER=prebuilt.example.com
```

Accepted options are:
- `BB_BUILD_JOBS`: set to `9` by default, it is the number of jobs to spawn when building packages
- `BB_TRASH_KEEP_DAYS`: set to `15` by default, it is the minimum time to keep files in the trash before automatically removing them
- `BB_DEBUG`: disabled by default, set to `1` to enable debug (very verbose in standard output)

There are also prebuilt target options which are detailed in [prebuilt target](target.md#pre-built-targets) section.

The system and user files are also the [shell plugin](shell_plugin.md#configuration)
configuration files, so they can hold `BBX_*` options such as
`BBX_PROMPT_ENABLED` next to the settings above. These options are read by the
host shell only: they have no effect in `.bbx/config`.

Settings are read every time a BuildBox command runs, so a change is taken into
account by the next command. However, the system and user configuration
directories are bind-mounted in the project container when it starts: if you
created `/etc/buildbox/` or `~/.config/buildbox/` while a container was already
running, stop it with `bbx instance stop` so that they are mounted again.

::: tip
The same settings can also be set as environment variables on the host before
running `bbx`, which is handy for a one-shot change:
```
BB_BUILD_JOBS=32 bbx target build
```
Note that a setting present in a `config` file takes precedence over the
environment.
:::

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
