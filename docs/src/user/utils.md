# Utilities

# Get prebuilt target

`buildbox_get_prebuilt` is a utility to easily get and use prebuilt target binaries.

Given a project tag and one of its target name, you can get prebuilt binaries
locally and use them directly.

To use it:
```
buildbox_get_prebuilt <project_tag> <target> [buildbox_version image_version]
```

where:
- `project_tag` is the tag of a project for which prebuilt targets have been released
- `target` is the prebuilt target to get
- `buildbox_version` is the BuildBox version on which the project was built (must be at least 1.3.15)
- `image_version` is the BuildBox container image version on which the project was built

When using this utility, the right versions of BuildBox are set, and the project prebuilt target is downloaded.
Once done, a BuildBox shell is opened on this target and you are ready to use prebuilt binaries and resources.
When the shell is closed, the project is removed, and BuildBox restored to its original versions.

If you want to keep the project and its prebuilt target for later use after shell close, set the `KEEP` environment:
```
KEEP=1 buildbox_get_prebuilt ...
```

::: tip
Please ensure `BB_PREBUILT_SERVER`, `BB_PREBUILT_USERNAME` and `BB_PREBUILT_PATH` are set, as explained in [pre-built targets section](/user/target.md#pre-built-targets).
:::
