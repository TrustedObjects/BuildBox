# Projects

A project stands for a deliverable build context, for example to produce a client project's deliverables.
It encompasses all the software and hardware targets for a particular delivery.

## Project profile

A project has a `.bbx/` directory which is a standalone Git repository containing the project profile.

The project directory itself is not a Git repository. Only `.bbx/` is tracked by Git.

A project then defines one or several targets in its profile directory, in files prefixed with `target.`. More information about targets is available on [targets documentation](target.md).

Every project profile contains a `packages` sub-directory, which can be a Git sub-module shared across projects or a plain directory.

Project packages sources are stored in `src/` at the project root.

## Create a new project

To create a new BuildBox project in the current directory (or a given `DIR`), use:
```
bbx init [--target TARGET] [--image IMAGE] [DIR]
```

This creates a `.bbx/` profile directory with its own Git repository, and an initial target profile.
The project directory itself is not a Git repository.
If `--target` is omitted, the target name defaults to `default`.

### Example

```
bbx init --target myplatform ~/workspace/my_project
```

### Custom Docker image

By default, BuildBox uses the `buildbox:latest` image (or the `BBX_IMAGE` environment variable if set).
A project may declare a custom Docker image with the `--image` option:

```
bbx init --image mycompany/buildbox-custom:latest ~/workspace/my_project
```

This creates a `.bbx/image` file containing the image reference. The file can also be created or updated manually at any time.
It accepts any Docker image reference: a Docker Hub name, a full registry URI, or a local image name:

```
# Official BuildBox image
buildbox:1.2.3

# Docker Hub image
mycompany/buildbox-custom:latest

# Private registry
registry.mycompany.com/buildbox-custom:2.1.0

# Local image (not pushed to any registry)
buildbox-custom:dev
```

When `.bbx/image` changes (or is added/removed), the next `bbx` command automatically stops the existing container and starts a new one using the updated image. No manual `bbx stop` is required.

The declared image is shown in `bbx project info`.

## Clone an existing project

To clone an existing BuildBox project, use:
```
bbx clone <url> [dir]
```

The URL points to the profile repository (the content that lives in `.bbx/`).
`bbx clone` creates the project directory and clones the profile repository into `<dir>/.bbx/`.
If `dir` is omitted, the directory is named after the repository.

### Example

```
bbx clone ssh://git@server/my_project_profile.git
```

## Get project information

To get project information, use:
```
bbx project info
```

Displayed information:
| Name | Description |
|------|-------------|
| Project | The project directory name |
| Path | Location of the project directory |
| Branch / Tag / Changeset | Project branch / tag / changeset |
| Packages changeset | Revision of project packages Git sub-module |
| Profile status | Is `clean` if the project profile is not modified, else `modified` |

## Update a project

To update a locally available project profile, use:
```
bbx project update
```

This updates the project profile (`.bbx/`) from its remote.

::: warning
This only updates the project profile, and does not update the packages themselves. You have to fetch and build targets explicitly after project update.
:::

## Commit project profile

The project profile lives in `.bbx/`, which is a standalone Git repository. To commit and push profile changes, navigate to profile first:

```bash
bbx project goto -p
git add .
git commit -m "Update profile"
git push
```

Don't forget the project profile may have a `packages` submodule, which may need to be committed if you made changes to it.

::: tip
You can check if the project profile has to be commited by running `bbx project info` and checking the `Profile status` field.
:::

## Clean project built files

To clean a project built files:
```
bbx project clean
```

It cleans the current project by removing built files for all its targets.

## Clean all project files

To clean all project files, except the project profile:
```
bbx project mrproper
```

This command wipes the current project by removing sources and built files for all its targets.
It is asked to user to confirm before wiping.

::: tip
Sources are sent to BuildBox trash, and are definitively removed after a while.
:::
