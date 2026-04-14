# Introduction

BuildBox main key concepts are [projects](project.md), [targets](target.md), [packages](package.md) and [tools](tool.md).

A [project](project.md) stands for deliverable components, and the way to build them.
It is componed by one or several [targets](target.md), which is the platform of a deliverable, defining build, test and distribution method.
[Targets](target.md) are embedding [packages](package.md), which are software components built for it.
And [tools](tool.md) are used by [targets](target.md) and involved in the build, test and distribution to release the deliverable.

BuildBox is used through the `bbx` command, directly from a project directory.
It works like any other command-line tool: no shell to enter, no workspace to configure.
Please run `bbx --help` to get a complete list of supported commands.

::: warning
BuildBox commands are not meant to be used from shell scripts if you need to deal with output data.
Indeed, output format is not fixed for BuildBox commands as they are to be used by humans.
So, if you have to deal with BuildBox from scripts and need to parse output data, consider using [BuildBox API](/dev/api.md).
:::
