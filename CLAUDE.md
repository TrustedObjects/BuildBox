# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is BuildBox

BuildBox is a containerized build environment framework (by Trusted Objects) that provides reproducible, isolated builds for embedded/firmware development projects. It manages projects, targets, packages, and tools via shell scripts, running inside a Docker container.

**Version 2.x** (current branch): `bbx` CLI tool, one Docker container per project, project root = cwd.
**Version 1.x** (legacy): `buildbox` shell-entry model, one shared container with multiple projects.

## Running Tests

```bash
# Run all tests
./tests/run_tests

# Run a specific test by name
./tests/run_tests test_bb_set_current_project

# Run with specific shell
MODE=zsh ./tests/run_tests

# Verbose output
VERBOSE=1 ./tests/run_tests
```

Tests must pass in **both Bash and Zsh** (critical requirement). The test framework is in `tests/testsuite.sh` with unit tests in `tests/cases/unit/` and functional tests in `tests/cases/functional/`.

## Documentation Site

```bash
cd docs
npm run dev      # Live development server
npm run build    # Production build
```

## Docker

```bash
docker build -t buildbox docker/
```

The host-side launcher is `docker/bin/bbx`. It manages one container per project, keyed by project root path.

## Architecture (2.x)

### Project Layout

A BuildBox 2.x project is a git repository with a `.bbx/` profile directory:

```
my_project/
├── .git/
├── .bbx/
│   ├── default_target        # symlink to the default target file
│   ├── target.<NAME>         # one file per target (defines CPU, PACKAGES, TOOLS, TESTS, DIST)
│   ├── packages/             # package definitions (plain folder OR git submodule)
│   │   └── foo.sh            # same format as 1.x: SRC_URI, SRC_PROTO, SRC_REVISION, SRC_BUILD
│   ├── packages.<TARGET>     # list of package names for each target
│   ├── tools.<TARGET>        # list of tool names for each target (optional)
│   ├── .state                # gitignored: current target name
│   ├── .cache/               # gitignored: file cache
│   ├── .tools/               # gitignored: installed tools
│   └── .trash/               # gitignored: soft-deleted items
├── src/                      # generated: cloned package sources (shared)
└── <TARGET>/                 # generated: per-target build tree
    ├── src/                  # target-specific sources (symlinks or copies)
    └── build/                # installed files (PREFIX)
```

### Key Environment Variables

| Variable | Value |
|---|---|
| `BB_PROJECT_DIR` | Git root of cwd (detected by finding `.bbx/`) |
| `BB_PROJECT` | Basename of `BB_PROJECT_DIR` (1.x compatibility) |
| `BB_PROJECT_PROFILE_DIR` | `$BB_PROJECT_DIR/.bbx` |
| `BB_PROJECT_SRC_DIR` | `$BB_PROJECT_DIR/src` |
| `BB_TARGET` | Current target name |
| `BB_TARGET_DIR` | `$BB_PROJECT_DIR/$BB_TARGET` |
| `BB_TARGET_SRC_DIR` | `$BB_TARGET_DIR/src` |
| `BB_TARGET_BUILD_DIR` | `$BB_TARGET_DIR/build` (= `PREFIX`) |
| `BB_CACHE_DIR` | `$BB_PROJECT_PROFILE_DIR/.cache` |
| `BB_TOOLS_DIR` | `$BB_PROJECT_PROFILE_DIR/.tools` |
| `BB_TRASH_DIR` | `$BB_PROJECT_PROFILE_DIR/.trash` |
| `BB_BUILD_JOBS` | Parallel build jobs (default: 9) |

### Code Layout

- `src/commands/bbx`: main CLI dispatcher (runs inside container), delegates to commands below
- `src/commands/`: all commands (public and internal):
  - Public: `build`, `fastbuild`->`build` (symlink), `clean`, `clone`, `mrproper`, `pkg`, `target`, `bbenv`, `bbx`
  - Project: `project_init`, `project_clone`, `project_migrate`, `project_clean`, `project_mrproper`, `project_info`, `project_update`
  - Target: `target_build`, `target_clean`, `target_clone`, `target_mrproper`, `target_dist`, `target_dist_prebuilt`, `target_fastbuild`, `target_info`, `target_list`, `target_pkg`, `target_set`, `target_test`, `target_tools`
- `src/`: API library files (sourced via `buildbox_utils.sh`, not executed):
  - `_project.sh`: project autodetect (`bb_detect_project_root`, `bb_autodetect_project`, `bb_set_current_project`)
  - `_target.sh`: target management; state persisted in `.bbx/.state`
  - `_build.sh`, `_build_*.sh`: build modes: autotools, make, custom, prebuilt
  - `_clone.sh`, `_clone_git.sh`, `_clone_http.sh`: package source cloning
  - `_package.sh`: package discovery and loading
  - `_tool.sh`: tools load/unload with cleanup hooks
  - `_locks.sh`: directory-based locks; held as `$BB_PROJECT_SRC_DIR/lock` during build/clone operations
  - `_local_env.sh`: cross-compilation env (`CFLAGS`, `CHOST`, `PREFIX`, `PATH`, etc.)
- `settings/zsh/`: ZSH configuration (`.zshrc`) and tab completion rules (`comp/`)
- `docker/bin/bbx`: host-side launcher; detects project root, starts per-project container, delegates most commands via `docker exec`. Exceptions: `bbx init`/`bbx migrate` run on the host directly; `bbx stop` calls `bb_unload_tools` inside the container before removal (allows tools such as `buildbox_docker_tools` to stop inner Docker daemons cleanly); `bbx instances list/stop` manage all running BuildBox containers across projects
- `tests/bundles/`: git bundles that store test fixture repository history (committed to BuildBox)
- `tests/repositories/setup.sh`: reconstructs fixture repos from bundles (called automatically by `run_tests`)
- `tests/repositories/`: gitignored; populated by `setup.sh`: project fixtures (`foo_project/`, `bar_project/`, `projects/`) and bare remote repos (`remote/*.git`)

### Shell Script Conventions

- All API functions are prefixed with `bb_`
- `bb_exportfn <fn>` exports a function with shell-option management and cwd restoration
- Subshell syntax `() (...)` used for isolation where side effects must be avoided
- All scripts must work in both **bash** and **zsh**
- `buildbox_utils.sh` is sourced at the top of every command script; it auto-detects the project from cwd (or `$BB_PROJECT_DIR` if already set in environment)

### Project Autodetection

`bb_autodetect_project` (called on every `source buildbox_utils.sh`) works as follows:

1. If `BB_PROJECT_DIR` is set and valid in the environment → use it directly (subprocess inheritance)
2. Else walk up from cwd until a `.bbx/` directory is found
3. Call `bb_set_current_project <root>` which sets all `BB_*` env vars and restores `BB_TARGET` from `.bbx/.state`

### Build Modes

Each package declares its build mode; the corresponding handler in `src/`:
- `_build_autotools.sh`: `./configure && make` (supports source sharing via symlinks)
- `_build_make.sh`: plain `make` (supports source sharing)
- `_build_custom.sh`: arbitrary build script (no source sharing, sources are copied)
- `_build_prebuilt.sh`: fetch and install a prebuilt binary

### Test Helper Functions

Tests use these helpers defined in `tests/testsuite.sh`:
- `bb_setup_test_project <fixture>`: copies fixture into `$BB_TEST_WORKSPACE`, returns path
- `bb_use_test_project <fixture> [target]`: setup + `bb_set_current_project` + optional target set
- All `assert*` functions: `asserteq`, `assertne`, `assertz`, `assertn`, `assertd`, `assertf`, `assertl`, etc.

## Style Rules

- Do not use the em dash character (--) in code or documentation. Use a colon or reword the sentence instead.
