# BuildBox shell

BuildBox provides an optional interactive shell, available via `bbx shell`.
It uses [ZSH](https://www.zsh.org).
Its configuration is located at `settings/zsh/.zshrc` and serves the following
purposes:
- [environment refresh](#environment-refresh) before running commands,
- [launch host applications](#host-applications),
- allow several commands to [change current working directory](#goto),
- [Completion](#completion)

## Environment refresh

Environment may be altered by different factors (target change,
tool installation...), see [Local environment](/dev/api.md#local-environment).

The environment is refreshed before every command, and before every prompt, ZSH
`precmd` and `preexec` hooks are used for this.

::: warning
There is a limit: when you paste several lines in BuildBox shell, the
environment is not refreshed between them. If one of them makes changes to the
environment, it is not seen by following commands.
:::

## Host applications

Host applications can be launched from BuildBox. The project being mounted at
the same path in the container, argument paths only need to be made absolute,
by `bb_path_to_host()`.

To start an application on host, pipes are used to communicate between
container and host. Such pipes are created every time a BuildBox launcher is
started, then every launcher has its dedicated communication pipes.
These pipes are stored in the project `tmp/` directory:
- send pipe, to send a command to the host: `$BB_PROJECT_DIR/tmp/launcher-$BB_LAUNCHER_ID_send.pipe`,
- return pipe, to get back the command return code in the container: `$BB_PROJECT_DIR/tmp/launcher-$BB_LAUNCHER_ID_ret.pipe`.

See `bb_host_send()` (container side) and `docker/bin/bbx` (host side) for
details on this pipes communication implementation.

Moreover, a file is used to store host application output, also reachable from
container: `$BB_PROJECT_DIR/tmp/launcher-$BB_LAUNCHER_ID_send.out`. See
`bb_host_send_print_out()` for details about this.

Finally, there are implementation functions for some applications to use this
mechanism: VS-Code, Meld, Gitk...). See
[host applications from BuildBox container](/user/container.md#host-applications).

## Goto

Several special commands allow to change current working directory of the shell:
`goto <package>`, `target goto` and `project goto`, see
[goto commands](/user/shell_plugin.md#goto-commands).

These commands are implemented in `settings/zsh/.zshrc`, and on the host side
by the [shell plugin](/user/shell_plugin.md).

## Completion

Completion rules are defined in `settings/zsh/comp` folder.
It is based on [ZSH completion system](https://zsh.sourceforge.io/Doc/Release/Completion-System.html).
