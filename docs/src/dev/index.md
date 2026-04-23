# Overview

In this section is presented everything required to develop in BuildBox.

BuildBox relies on its [API](/dev/api.md) to provide its environment and
commands to the user.

Below is presented BuildBox repository sources structure. The folders are
organized like this:
- `src/`: scripts
  - `commands/`: all executables (public and internal), including `bbx` the container-side CLI entry point
  - `_*.sh`: BuildBox API library files (sourced, not executed)
  - `buildbox_utils.sh`: API entry point
- `settings/zsh/`: [BuildBox shell settings](shell.md)
- `docker/`: [BuildBox container](container.md) stuff, including the host-side `bbx` launcher

Public executable files are accessible from inside the container by users.

Internal executable files are used only by BuildBox itself.
These files, located in `src/commands/`, have no `.sh` extension and are not
meant to be executed directly.

[BuildBox API](/dev/api.md) is implemented as `src/_*.sh` files.
