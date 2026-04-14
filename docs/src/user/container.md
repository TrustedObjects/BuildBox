# BuildBox container

BuildBox runs in a Docker container to isolate the build environment from the host system.

A dedicated container is automatically created and managed for each project.
When you run `bbx` from a project directory, the container is started if needed,
and the command is executed inside it.
You do not need to manage the container lifecycle manually.

The container is named after the project directory, so each project has its own
isolated build environment.

The following settings are shared between host user and container:
- SSH
- Git
- Vim

![BuildBox container](/buildbox_container_structure.png)

## Manage container images

The BuildBox container image is published on Docker Hub at
[trustedobjects/buildbox](https://hub.docker.com/r/trustedobjects/buildbox).

### List images

```
bbx image list [--all]
```

Lists all locally available BuildBox images. With `--all`, also lists the tags
available on Docker Hub.

### Fetch an image

```
bbx image fetch [TAG]
```

Pulls the image from Docker Hub and makes it available locally as
`buildbox:<TAG>`. If `TAG` is omitted, `latest` is used.

::: tip
After fetching a new image, run `bbx instance upgrade` to apply it to all
existing project containers.
:::

## Manage projects containers

Although the container lifecycle is handled automatically, a set of commands is
available to inspect and manage all running instances from the host.

### List instances

```
bbx instance list
```

Lists all currently running BuildBox containers with their associated project
directory and status (`idle` or `busy`).

### Stop instances

```
bbx instance stop [--force] [NAME...]
```

Stops all idle running instances. An instance is considered busy when a build or
clone operation is in progress. Busy instances are skipped unless `--force` is
passed, which stops them immediately regardless of their state.

One or more container names (as shown by `bbx instance list`) can be passed to
restrict the operation to specific instances.

To stop the container for the current project only, use `bbx stop` from inside
the project directory.

### Upgrade instances

```
bbx instance upgrade [--image IMAGE] [NAME...]
```

Removes and restarts all project containers that were created from an older
image, so they immediately run with the new image. Containers already using the
target image are left untouched and reported as `up-to-date`.

This command inspects both running and stopped containers. By default it
upgrades to `buildbox:latest`. Pass `--image` to target a specific local image.

Optionally, one or more container names (as shown by `bbx instance list`) can
be passed to restrict the upgrade to specific projects.

::: tip
The typical upgrade sequence is:
```
bbx image fetch
bbx instance upgrade
```
:::

## Access project files from host

Your project directory is mounted into the container at the same absolute path.
So a file at `~/workspace/my_project/src/my_package` on the host is accessible at the same path from inside the container.

You can open your project sources in your favorite editor directly from the host,
since the project directory is a regular directory in your home.

## Host applications

BuildBox can run few host applications, allowing to invoke them from its interactive shell (`bbx shell`).

Supported applications are:
- `code`, which calls Visual Studio Code,
- `meld`, a file comparison tool,
- `gitk`, a Git repository browser,
- `nautilus`, Gnome file browser, by default running in current directory,
- `evince`, Gnome PDF reader,
- `gedit`, Gnome file editor.

## X11 applications

GUI applications can be run from BuildBox seamlessly, through host's X11
server.
As BuildBox container user ID and group ID are the same as your host's ones, there
is nothing special to do to allow BuildBox to use host's X11 server.
