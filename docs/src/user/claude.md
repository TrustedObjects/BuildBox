# Working with Claude Code

BuildBox ships skills for [Claude Code](https://claude.com/claude-code), so that it knows the
BuildBox environment when working on your projects: the layout, the commands, the targets and
the API. They are installed with BuildBox, and they follow its updates.

Nothing related to Claude is created until you ask for it.

## Install

Once per user, after BuildBox is installed:

```
bbx claude install
```

This links the skills shipped by BuildBox into `~/.claude/skills/`, and records that you work
with Claude. Being links, they always describe the BuildBox version currently installed, so
there is nothing to redo after an upgrade.

To remove them:

```
bbx claude uninstall
```

## Without BuildBox installed from sources

The same skills are published as a Claude Code plugin, in the
[BuildBox-claude](https://github.com/TrustedObjects/BuildBox-claude) marketplace:

```
/plugin marketplace add TrustedObjects/BuildBox-claude
/plugin install buildbox@trusted-objects
```

That channel follows the latest BuildBox **release**, while `bbx claude install` follows the
version installed on your machine. Prefer `bbx claude install` when you have BuildBox
installed, and the plugin otherwise.

## What the skills cover

| Skill | Purpose |
|-------|---------|
| `buildbox` | Working on a project: targets, packages, tools, container, deliveries |
| `buildbox-scripting` | Writing scripts run by BuildBox: target tests and deliveries, package builds, tools |
| `buildbox-develop` | Working on BuildBox itself |

Each one carries the reference documentation it needs, generated from this documentation, so
Claude reads the same source of truth as you do, offline included.

## Project guidance

Once the skills are installed, `bbx init` and `bbx clone` create two files in a project:

- `.bbx/CLAUDE.md`, in the project profile, therefore **versioned and shared** with everyone
  working on the project. Describe there what is specific to the project: what it delivers,
  what each target is for, the manual steps if any remain. This is the file to maintain.
- `CLAUDE.md` at the project root, which only imports the first one so that it is found from
  the project directory. It is generated, there is nothing to write in it.

Running `bbx claude install` inside an existing project creates the missing ones. An existing
file is never modified.

::: tip
The skills describe BuildBox, `.bbx/CLAUDE.md` describes your project. Keeping the two apart
is what makes the project file worth committing.
:::
