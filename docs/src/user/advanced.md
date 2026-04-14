# Advanced features

## Settings

BuildBox settings defaults can be changed in `.bbx/custom_config` file at the project root.

Accepted options are:
- `BB_BUILD_JOBS`: set to `9` by default, it is the number of jobs to spawn when building packages
- `BB_TRASH_KEEP_DAYS`: set to `15` by default, it is the minimum time to keep files in the trash before automatically removing them
- `BB_DEBUG`: disabled by default, set to `1` to enable debug (very verbose in standard output)

There are also prebuilt target options which are detailed in [prebuilt target](target.md#pre-built-targets) section.

## Shell prompt integration

BuildBox can display project information directly in your host shell prompt
(Bash and ZSH are supported). The segment appears at the leftmost position of
the prompt line when you enter a BuildBox project directory, and disappears
automatically when you leave.

### Prompt segment anatomy

```
● BuildBox:target user@host:~/my_project$
```

| Part | Meaning |
|---|---|
| `●` in **green** | BuildBox container is running for this project |
| `●` in **red** | No container running (stopped or never started) |
| `:target` | Active target name, in blue (absent if no target is set) |

The segment updates before every command, so switching targets with
`bbx target set <name>` is reflected immediately at the next prompt.

### Short commands

When the prompt plugin is active, the following commands become available
without the `bbx` prefix as soon as you enter a BuildBox project directory.
They are removed when you leave. Existing aliases or functions with the same
name in your shell are left untouched.

**bbx subcommands:**

| Short form | Equivalent |
|---|---|
| `project <subcmd>` | `bbx project <subcmd>` |
| `target <subcmd>` | `bbx target <subcmd>` |
| `fetch` | `bbx fetch` |
| `build [pkg]` | `bbx build [pkg]` |
| `fastbuild [pkg]` | `bbx fastbuild [pkg]` |
| `clean [pkg]` | `bbx clean [pkg]` |
| `mrproper` | `bbx mrproper` |
| `pkg <subcmd>` | `bbx pkg <subcmd>` |
| `shell` | `bbx shell` |

`env` is intentionally excluded as it conflicts with the standard system command.

**Goto commands** (change directory in the host shell):

| Command | Destination |
|---|---|
| `target goto` or `tg` | Current target directory (`$project/$target/`) |
| `project goto` or `pg` | Project root directory |
| `project goto -p` or `pp` | Project profile directory (`.bbx/`) |
| `goto <pkg>` | Package source directory |
| `goto <pkg> -b` | Package build directory |

`goto` resolves partial package names and disambiguates multiple matches.

**Short aliases:**

| Alias | Equivalent |
|---|---|
| `tb` | `target build` |
| `tfb` | `target fastbuild` |
| `ts` | `target set` |
| `tg` | `target goto` |
| `pg` | `project goto` |
| `pp` | `project goto -p` |

### Activation

After `make install`, add the following line to your `~/.bashrc` (Bash) or
`~/.zshrc` (ZSH):

```bash
source /usr/local/share/buildbox/shell/bbx-prompt.sh
```

Adjust the path if you installed BuildBox to a custom `PREFIX`.

### Disabling the prompt segment

Create `~/.config/buildbox/config` (or `$XDG_CONFIG_HOME/buildbox/config`) and
set:

```bash
BBX_PROMPT_ENABLED=0
```

The file is sourced every time a new shell starts, so the change takes effect in
the next terminal session.

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
If adding package or changing configuration as administrator, you should discuss with your BuildBox maintainer to make these changes available in the future container image release ! Else, you will have an environment not synchronized with other developers working on the same projets than you.
:::
