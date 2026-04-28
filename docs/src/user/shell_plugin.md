# BuildBox shell plugin

BuildBox ships an optional plugin for the host shell (bash and zsh) that adds
project-aware behavior:

- a prompt segment showing the current project target and container state,
- short command aliases (`target`, `build`, `fetch`...) available only inside
  a project,
- `goto` commands to jump to the target, project, or package directory,
- automatic export of BuildBox environment variables.

The plugin is opt-in. When not sourced, your shell is unchanged.

## Installation

Add the following line to your `~/.bashrc` or `~/.zshrc`:

```bash
source /usr/local/share/buildbox/shell/bbx-prompt.sh
```

If BuildBox was installed with a custom prefix, adjust the path accordingly
(`<PREFIX>/share/buildbox/shell/bbx-prompt.sh`).

The plugin can be sourced multiple times safely.

## Prompt segment

When the current directory is inside a BuildBox project, a segment is prepended
to the prompt:

```
● BuildBox:target  user@host [~/src/my_project] %
```

- a green dot means the project container is running,
- a red dot means it is stopped,
- the target name after the colon comes from `state` at the project root.

Outside a project, the segment disappears.

## Command aliases

Inside a project, the following aliases and functions are defined. They are
removed when leaving the project tree. Any name that is already an alias or
function in your shell is not overridden.

Subcommand shortcuts (equivalent to `bbx <cmd>`):

| Alias              | Expands to                  |
|--------------------|-----------------------------|
| `fetch`            | `bbx fetch`                 |
| `build [pkg]`      | `bbx build [pkg]`           |
| `fastbuild [pkg]`  | `bbx fastbuild [pkg]`       |
| `clean [pkg]`      | `bbx clean [pkg]`           |
| `mrproper`         | `bbx mrproper`              |
| `pkg`              | `bbx pkg`                   |
| `shell`            | `bbx shell`                 |
| `target <subcmd>`  | `bbx target <subcmd>`       |
| `project <subcmd>` | `bbx project <subcmd>`      |

`env` is intentionally excluded as it conflicts with the standard system command.

Short target/project aliases:

| Alias  | Expands to              |
|--------|-------------------------|
| `tb`   | `bbx target build`      |
| `tfb`  | `bbx target fastbuild`  |
| `ts`   | `bbx target set`        |

## Goto commands

These functions change the current working directory of the shell. They run on
the host, so your shell location actually moves.

| Command             | Destination                              |
|---------------------|------------------------------------------|
| `goto <pkg>`        | package source directory                 |
| `goto <pkg> -b`     | package build directory                  |
| `target goto` / `tg`| current target directory                 |
| `project goto`/`pg` | project root directory                   |
| `project goto -p`/`pp` | project `.bbx` profile directory      |

`goto` resolves partial package names and disambiguates multiple matches. These work with or without the `bbx` prefix.

## Environment variables

While the current directory is inside a project (the project root or any
subdirectory), the plugin exports BuildBox project and target variables in
your shell so they can be used in any command:

| Variable                   | Value                                         |
|----------------------------|-----------------------------------------------|
| `BB_PROJECT_DIR`           | project root absolute path                    |
| `BB_PROJECT`               | project directory basename                    |
| `BB_PROJECT_PROFILE_DIR`   | `$BB_PROJECT_DIR/.bbx`                        |
| `BB_PROJECT_SRC_DIR`       | `$BB_PROJECT_DIR/src`                         |
| `BB_CACHE_DIR`             | `$BB_PROJECT_DIR/cache`                       |
| `BB_TOOLS_DIR`             | `$BB_PROJECT_DIR/tools`                       |
| `BB_TRASH_DIR`             | `$BB_PROJECT_DIR/trash`                       |
| `BB_TARGET`                | contents of `state` (current target)     |
| `BB_TARGET_DIR`            | `$BB_PROJECT_DIR/$BB_TARGET`                  |
| `BB_TARGET_SRC_DIR`        | `$BB_TARGET_DIR/src`                          |
| `BB_TARGET_BUILD_DIR`      | `$BB_TARGET_DIR/build`                        |

The target variables are only exported when a current target is set in
`state` at the project root. If you run `bbx target set <other>` inside the project, the
target variables are refreshed at the next prompt.

When you leave the project tree, all of these variables are unset.

::: warning
If you have manually exported any `BB_*` variable in your shell before the
plugin ran, it will be overwritten when you enter a project and unset when you
leave. To keep your own value, disable the auto-export (see below).
:::

## Configuration

User configuration is read from `~/.config/buildbox/config` (or
`$XDG_CONFIG_HOME/buildbox/config`). Two flags are available:

```bash
# Disable the whole plugin: no prompt segment, no aliases, no env export
BBX_PROMPT_ENABLED=0

# Keep the prompt and aliases, but disable environment variable auto-export
BBX_ENV_EXPORT_ENABLED=0
```

Both default to `1`.
