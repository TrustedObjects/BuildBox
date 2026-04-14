# Projects

A project stands for a deliveries building context, for example to produce a client project deliverables.
It aims to concern all the software and hardware targets for a particular delivery.

## Project profile

A project is a Git repository containing a `.bbx/` profile directory.

The project profile is available at `.bbx/` in the project root directory.

A project then defines one or several targets in its profile directory, in files prefixed with `target.`. More information about targets is available on [targets documentation](target.md).

Every project profile contains a `packages` sub-directory, which can be a Git sub-module shared across projects or a plain directory.

Project packages sources are stored in `src/` at the project root.

## Create a new project

To create a new BuildBox project in the current directory (or a given `DIR`), use:
```
bbx init [--target TARGET] [DIR]
```

This creates a Git repository with a default `.bbx/` profile structure and an initial target profile.
If `--target` is omitted, the target name defaults to `default`.

### Example

```
bbx init --target myplatform ~/workspace/my_project
```

## Clone an existing project

To clone an existing BuildBox 2.x project, use:
```
bbx clone <url> [dir]
```

This clones the project Git repository with all its submodules.
If `dir` is omitted, the directory is named after the repository.

### Example

```
bbx clone ssh://git@server/my_project.git
```

## Migrate a legacy project

To migrate a BuildBox 1.x project branch to a new standalone 2.x project, use:
```
bbx migrate --url <legacy_url> --branch <branch> [--output <dir>]
```

This clones the legacy project branch, renames the branch to `master`, moves all profile files into `.bbx/`, and creates a `.gitignore` covering BuildBox generated directories.
The packages submodule, if any, is moved from `packages` to `.bbx/packages`.

### Example

```
bbx migrate --url ssh://git@server/projects.git --branch my_project
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
This only updates the project profile, and does not update the packages themselves. You have to fetch and build targets explicitely after project update.
:::

## Commit project profile

The project directory is a Git repository, so you can use Git directly to commit and push profile changes.

Don't forget the project profile may have a `packages` submodule, which may need to be commited if you made changes on it.

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
Sources are sent to BuildBox trash, and are definively removed after a while.
:::
