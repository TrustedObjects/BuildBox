# Projects

A project stands for a deliverable build context, for example to produce a client project's deliverables.
It encompasses all the software and hardware targets for a particular delivery.

<ProjectLayout highlight="project" />

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
bbx clone [-b BRANCH] <url> [dir]
```

The URL points to the profile repository (the content that lives in `.bbx/`).
`bbx clone` creates the project directory and clones the profile repository into `<dir>/.bbx/`.
If `dir` is omitted, the directory is named after the repository.
Use `-b` to check out a specific branch or tag (default: the repository's default branch).

### Examples

```
bbx clone ssh://git@server/my_project_profile.git
bbx clone -b dev ssh://git@server/my_project_profile.git my_project
```

## Fetch, build, test and deliver every target

The following commands run over **every target** of the project:
```
bbx project clone [-n|--not NAME]... [--stop-on-error] [OPTIONS...]
bbx project build [-n|--not NAME]... [--stop-on-error] [OPTIONS...]
bbx project test  [-n|--not NAME]... [--stop-on-error] [OPTIONS...]
bbx project dist  [-n|--not NAME]... [--stop-on-error] [OPTIONS...]
```

Each target is processed by the matching `bbx target` command, so every target
keeps its own logs and its own behaviour, and `OPTIONS...` are passed to it as
they are (`bbx project build -v`, `bbx project dist 1.2.3`).

`bbx project clone -u` is the one to know: it updates what is already cloned in
every target, instead of leaving it as it is, exactly as
[`bbx target clone -u`](target.md#fetch-target) does for the current target.

::: tip
`bbx project clone` fetches sources, while `bbx clone <url>` gets a whole
project: the first works inside a project, the second creates one.
:::

A target which cannot be concerned is skipped rather than counted as a failure:
`test` skips a target defining no `TESTS`, and `dist` one defining no `DIST`.
`clone` and `build` apply to every target.

`-n` leaves a target out, and can be repeated once per target to exclude:
`bbx project build --not doc --not test-bench`. Naming a target the project
does not have prints a warning, the run going on with the others: an exclusion
which no longer matches anything is a typo worth seeing.

By default a failing target does not stop the others, so a single run tells the
state of the whole project. With `--stop-on-error` the command stops at the
first failure, and the targets left untouched are reported as `not run`.

The current target is restored when the command ends.

A report closes the run, one line per target:
```
Project build report
  TARGET  RESULT    WARNINGS
  foo     ok        2
  bar     failed    -
  qux     not run   -
  doc     excluded  -
```

`RESULT` is `ok`, `failed`, `skipped`, `excluded` or `not run`. `WARNINGS` counts the build
warnings of the target, and is only shown by `bbx project build`, the other
actions producing none. The command
exits with an error as soon as one target failed, which makes it usable as a
continuous integration step.

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
bbx project update [-a|--all]
```

This updates the project profile (`.bbx/`) from its remote.

With `-a`, the sources of every target are updated too, once the profile is up
to date, exactly as [`bbx project clone -u`](#fetch-build-test-and-deliver-every-target)
does. This is usually what you want after a profile update: the profile is what
says which targets exist, which packages they use and which of them share their
sources, so the targets follow what has just changed.

::: warning
Without `-a`, only the project profile is updated: the packages sources stay as
they are, and it is up to you to fetch and build the targets afterwards.
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

::: note
The `tools/` and `cache/` directories are kept intact: installed tools and cached downloads are not removed.
:::
