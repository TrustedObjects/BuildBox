# Version migrations

This page lists the changes requiring an action on existing projects, from the
most recent BuildBox version to the oldest one. Upgrading BuildBox itself is
described in the [installation guide](/getting-started/install.md).

Only projects using the features listed below are concerned: when nothing
matches your project, there is nothing to do.

## From 2.0.2 to 2.1.0

### Target build settings are no longer built in

BuildBox no longer knows any CPU nor any toolchain: compilation flags, link
flags and toolchain triplet are now read from the target file only. See
[target build settings](target.md#target-build-settings) for the complete
reference.

**Concerned projects:** projects having a target whose `CPU` was one of
`arm-linux`, `cortex-m0`, `cortex-m3`, `cortex-m4`, `cortex-m7`, `cortex-m23`,
`cortex-m33`, `cortex-m35P`, `cortex-m55`, `lx6` or `lx7`. Targets building for
the machine running BuildBox (`CPU=x86`, or no `CPU` at all) are not concerned.

**What to do:** for each concerned target, add to its `.bbx/target.<TARGET>`
file the settings given below for its `CPU`. Values are the ones BuildBox was
applying silently, so the build result is unchanged.

::: tip
`CPUDEF` is not listed below, except for `arm-linux`: for every other CPU it
keeps its previous value without being declared, as it now defaults to the
`CPU` value uppercased (`CPU=cortex-m33` gives `CPUDEF=CORTEX_M33`).

`CPU_DESCRIPTION` is not listed either: it now defaults to the `CPU` value
(`cortex-m33` instead of `Cortex-M33` previously). As it is a human readable
string, declare it only if you display it somewhere.
:::

#### ARM Cortex-M

Settings to add to every Cortex-M target file:
```
CPU_FAMILY=ARM
CHOST=arm-none-eabi
LDFLAGS="-specs=nosys.specs -specs=nano.specs"
```

Plus the `CFLAGS` line matching the target `CPU`:

| `CPU` | Line to add |
|-------|-------------|
| `cortex-m0` | `CFLAGS="-mcpu=cortex-m0plus -mthumb -mfloat-abi=soft -mgeneral-regs-only"` |
| `cortex-m3` | `CFLAGS="-mcpu=cortex-m3 -mthumb -mfloat-abi=soft -mgeneral-regs-only"` |
| `cortex-m4` | `CFLAGS="-mcpu=cortex-m4 -mthumb -mfloat-abi=soft -mgeneral-regs-only"` |
| `cortex-m7` | `CFLAGS="-mcpu=cortex-m7 -mthumb -mfloat-abi=soft -mgeneral-regs-only"` |
| `cortex-m23` | `CFLAGS="-mcpu=cortex-m23 -mthumb -mfloat-abi=soft -mcmse -mgeneral-regs-only"` |
| `cortex-m33` | `CFLAGS="-mcpu=cortex-m33 -mthumb -mfloat-abi=soft -mcmse -mgeneral-regs-only"` |
| `cortex-m35P` | `CFLAGS="-mcpu=cortex-m35p -mthumb -mfloat-abi=soft -mcmse -mgeneral-regs-only"` |
| `cortex-m55` | `CFLAGS="-mcpu=cortex-m55 -mthumb -mfloat-abi=hardfp -mcmse -mgeneral-regs-only"` |

::: warning
Note that `cortex-m0` was built with `-mcpu=cortex-m0plus`, and `cortex-m35P`
with `-mcpu=cortex-m35p`. Keep these values to build exactly as before, this is
also the opportunity to fix them if they were not what your target needs.
:::

Any other `CPU` starting with `cortex-m` was built with `CPU_FAMILY=ARM`,
`CHOST=arm-none-eabi`, `LDFLAGS="-specs=nosys.specs -specs=nano.specs"`,
`CFLAGS="-mthumb"` and an empty `CPUDEF`. Now that CPU are freely defined, use
this occasion to describe such a target completely.

Complete example, for a target file which was:
```
CPU=cortex-m33
TOOLS=tools.prod
PACKAGES=packages.prod
DESCRIPTION="Secure firmware"
```

and becomes:
```
CPU=cortex-m33
CPU_FAMILY=ARM
CHOST=arm-none-eabi
CFLAGS="-mcpu=cortex-m33 -mthumb -mfloat-abi=soft -mcmse -mgeneral-regs-only"
LDFLAGS="-specs=nosys.specs -specs=nano.specs"
TOOLS=tools.prod
PACKAGES=packages.prod
DESCRIPTION="Secure firmware"
```

#### ARM Linux

Settings to add to a `CPU=arm-linux` target file:
```
CPU_FAMILY=ARM-LINUX
CPUDEF=ARM
CHOST=arm-none-linux-gnueabihf
```

`CPUDEF` must be declared here: without it, it would now be `ARM_LINUX` instead
of `ARM`. No specific `CFLAGS` nor `LDFLAGS` were applied for this CPU.

#### Xtensa LX6 and LX7

Settings to add to a `CPU=lx6` or `CPU=lx7` target file (they are the same for
both):
```
CPU_FAMILY=XTENSA
CHOST=xtensa-esp32-elf
CFLAGS="-mlongcalls -ffunction-sections -fdata-sections"
LDFLAGS="-specs=nosys.specs -specs=nano.specs -Wl,--gc-sections -static"
```
