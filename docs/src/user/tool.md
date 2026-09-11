# Tools

Tools are similar to packages, but with the following differences:

- they must be prebuilt (using `prebuilt` or `executable` build mode),
- they are installed globally (required by some targets, but shared between them).

As packages, tools are represented by a file in the project profile `.bbx/packages` sub-directory.
In case of `executable` build mode, the single downloaded file is automatically put into the tool's `bin` directory and made executable.

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

Referenced tools are named like packages in project package sub-module, path prefix included.
A revision is specified the same way as for [packages](package.md#target-packages-list): prefixed by an `@` sign for a tag, a branch or a changeset, or prefixed by a `-` sign for numeric values separated by dots `.`. As for packages, a revision may contain `/`, as branch names often do.
Contrary to packages, tools do not accept options because tools are supposed to be prebuilt.

Example:
```
# Tool1 taken on its default revision, the one its package file specifies
tool1

# Tool2 on tag 1.2.3
tool2-1.2.3

# Tool3 on tag or branch 1.2.3
tool3@1.2.3

# Tool4 on branch release/1.2
tool4@release/1.2

# Tool5, whose package file is in the 'subdir' sub-directory
subdir/tool5
```

Each tool is installed in the project `tools` directory, in a directory named after the tool, without its path prefix and with the `/` of its revision replaced by `_`. In the example above, `tool4@release/1.2` is installed in `tools/tool4@release_1.2`, and `subdir/tool5` in `tools/tool5`.

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
| [SBOM tools](https://github.com/TrustedObjects/BuildBox-sbom-tools) | Generates the SBOM of a target, in SPDX and CycloneDX |

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

### BuildBox SBOM tools

BuildBox SBOM tools generates the Software Bill of Materials of a target, in
SPDX 2.3 and CycloneDX 1.6, for Cyber Resilience Act compliance.

A target already declares every component of a delivery, each pinned to an
exact revision: the package list is a SBOM skeleton. The tool formats it, and
expands the packages which themselves contain many components, such as a
firmware built from a distribution, or a container image.

It brings the `bbx-sbom` command, which has to be called once the target is
built, so from its [delivery script](/user/target.md#target-test-and-delivery-scripts):

```bash
bbx-sbom
```

What is reported comes from the package files, through optional `SBOM_*` fields
sitting next to the `SRC_*` ones: the licence, the supplier, the CPE, whether a
package is shipped, needed only to build or out of the document, which plugin
expands it, and which source URL to publish when the one BuildBox clones from
must not appear. See the tool
[documentation](https://github.com/TrustedObjects/BuildBox-sbom-tools) for the
whole list.
