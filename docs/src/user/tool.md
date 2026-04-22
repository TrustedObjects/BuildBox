# Tools

Tools are similar to packages, but with the following differences:

- they must be prebuilt,
- they are installed globally (required by some targets, but shared between them).

As packages, tools are represented by a file in the project profile `.bbx/packages` sub-directory.

Tools file tree structure can be understood by BuildBox, as it is structured as
follows (everything is optional):
- bin
- sbin
- lib
  - pkgconfig
  - python/site-packages
- share
  - pkgconfig
  - aclocal
- include
- load.sh
- unload.sh

Tools are required by target through a tools listing file, formatted with a tool by line.
Example:
```
tool1
tool2-1.2.3
```

Referenced tools are nammed like packages in project package sub-module.
Contrary to packages, tools do not accept options because tools are supposed to be prebuilt.

Example of tools:

- Cortus toolchain
- ARM toolchain
- Criterion

## Tools hooks

Scripts `load.sh` and `unload.sh` located at tool root directory are optional actions to be done when tool is loaded and unloaded by BuildBox.
There is also `cleanup.sh` to allow tool to cleanup resources on `bbx target mrproper` or `bbx project mrproper`.

These scripts should be **as efficient as possible**, and they have to ensure already done actions are not done again if not required.
These script don't have to be executable.

They may only do things related to the current target context, and runtime environment cleanup has to be done on `unload.sh` call.
Environment cleanup related to resources located out of the target is to be done from `cleanup.sh` hook.

As these scripts are sourced by BuildBox, they:
- **must not** call `exit`
- **must not** alterate BuildBox environment
- **must not** change interpreter behavior

The `load.sh` script has access to full BuildBox environment (excepted environment related to tools loaded after the concerned tool), but `unload.sh` only has access to:
- `BB_PROJECT_DIR`
- `BB_TARGET`,
- and environment defined by `load.sh`.

The `cleanup.sh` script has no access to environment defined for the tool. Indeed, tools are unloaded before cleanup.
So `PATH`, `XDG_DATA_DIRS`, `PYTHONPATH`, ... doesn't include your tool paths.

The tools appearance order in tools list is used to execute `load.sh` scripts, and the reverse order is used to execute `unload.sh` scripts.

## BuildBox official tools

| Tool | Description |
|---|---|
| [Docker tools](https://github.com/TrustedObjects/BuildBox-docker-tools) | Manages a Docker daemon in a BuildBox target environment |
| [Python tools](https://github.com/TrustedObjects/BuildBox-python-tools) | Manage BuildBox targets Python virtual environments |

### BuildBox Docker tools

BuildBox Docker tools manages a Docker daemon inside the BuildBox container,
allowing projects to build Docker images as part of their build process.

This tool requires a Docker-capable BuildBox image. The project must declare
the `buildbox-docker` image (or a custom image derived from it) in its
`.bbx/image` file:

```
buildbox-docker:M.m.r
```

See [Docker variant image](/dev/container.md#docker-variant-image) for how to
build and tag that image.
