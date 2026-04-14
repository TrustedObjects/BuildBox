# Develop BuildBox API

BuildBox API is implemented as `src/_*.sh` files.
The `src/` directory contains:
- API library files, with name formatted as `_*.sh`, not executable,
- `buildbox_utils.sh`, the API entry point.

All BuildBox commands (both public and internal) are located in `src/commands/`.

::: warning
Written code has to be compatible with Bash and ZSH.
:::

## Create API file

Name API files with the following format: `_*.sh`, and make it **not**
executable.

Every API file must start with the following:
``` shell
## @brief Description of this file

```
with the empty newline.

Details can be documented:
``` shell
## @brief Description of this file
## Comment line 1
## Comment line 2
##
## Comment line 3

```

::: tip
Markdown syntax can be used in these comments.
:::

## Create API function

API functions take place in [API files](#create-api-file).

Every API function must be prefixed with `bb_`, and exported to BuildBox API
through [bb_exportfn()](api.md#bb-exportfn).
Example of such function declaration:
``` shell
function bb_foo {
	local bar=0
	# function code
}
bb_exportfn bb_foo
```

If not required, API functions must not affect caller with environment or
current working directory changes.
To prevent this, if your function is declaring environment variables or
changing directory, you can declare use the following syntax to use a subshell:
``` shell
function bb_foo () (
	bar=0
	# function code
)
bb_exportfn bb_foo
```

Function variables have to use the `local` keyword, except for subshell
functions.

::: warning
Use subshell functions with care as they are less efficient than standard
functions.
:::

### Documentation

Every API function has to be documented. Documentation lines are prefixed with
`## `.
The following tags can be used:
- `@fn`: function name
- `@param`: parameter details
- `@env`: required environment variable
- `@setenv`: environment variable set by this function
- `@resetenv`: environment variable unset by this function
- `@print`: output text details
- `@return`: possible returned values details

For `@param`, `@env`, `@setenv` and `@resetenv`, there may be several
**contiguous** entries.

Example:
``` shell
## @fn bb_foo
## Description.
## Some details.
## @param Parameter details
## @param Another parameter details.
## @env `FOO` required environment details
## @env `FOO2` another required environment details
## @setenv `BAR` set environment details
## @resetenv `BAR2` reset environment details
## @print Output details.
## @return Returned values details
function bb_foo {
	# function code
}
bb_exportfn bb_foo
```

## Tests

BuildBox provides its own test environment, which allows two kinds of tests:
- [API functions unit tests](#test-api-functions), to validate BuildBox API is
working as expected,
- and [functional tests](#functional-tests), to validate user interface
behavior.

This test environment is located in the `tests` folder, and structured like
this:
- `cases/unit/\<category\>/`: [API functions unit tests](#test-api-functions),
having one `.sh` file for each API function, including several tests for the
function.
- `cases/functional/\<command\>/`: [functional tests](#functional-tests),
having one `.sh` file for each BuildBox shell command feature.

### Write test case

A test can be written as follows:

```shell
function test_<name>[-details] {
	# test case code
}
bb_declare_test test_<name>[-details]
```

- Test functions must be prefixed with `test_`.
- `<name>` is the test name (API name, or feature name for functional tests).
- `[-details]` is a short description about a test variant.

From a test case function, you can use the following assertions:
- `assert <v>`: generic assertion, success if `v` is evaluated successfully
- `asserteq <a> <b>`: success if `a` and `b` are equal (strings, integers)
- `assertne <a> <b>`: success if `a` and `b` are different (strings, integers)
- `assertz <a>`: success if `a` is not defined
- `assertn <a>`: success if `a` is defined (string)
- `assertd <d>`: success if `d` is a directory (absolute path)
- `assertnd <d>`: success if `d` is not a directory (absolute path)
- `assertf <f>`: success if `f` is a file (absolute path)
- `assertnf <f>`: success if `f` is not a file (absolute path)
- `assertl <f>`: success if `f` is a symbolic link (absolute path)
- `assertnl <f>`: success if `f` is not a symbolic link (absolute path)
- `assert_exists <f>`: success if `f` exists, whatever it is)
- `assert_does_not_exists <f>`: success if `f` doesn't exists
- `assert_in_path_list <p> <l>`: success if `p` path is in path list `l`, elements are separated by colon `:`
- `assert_is_subpath_of <p> <c>`: success if `p` path is parent of `c` path

On error, assertions terminate test case and the test is marked as failed.

Helpers are also available:
- `skip <message>`: skip the test without error
- `unformat_string <string>`: remove ANSI string formatting
- `minspace_string <string>`: remove useless spaces between words, startingi/ending spaces, and blank lines
- `is_subpath_of <p> <c>`: success (0) if `p` path is parent of `c` path

[Test data](#test-data) is available to help writing tests.

#### Test API functions

Every API function should be individually testable. Success and error cases
have to be validated, with returned data and also wrong inputs.

To add a test for a function of the API, you have to create a test cases file in
`cases/unit/\<category\>/<api_function_name>.sh`, and implement in this file
one or several test cases.

#### Functional tests

These tests are covering functional operations from BuildBox user interface.

To add a functional test, you have to create a test cases file in
`cases/functional/\<command\>/<case>.sh`, and implement in this file
one or several test cases.

### Run tests

To start tests, run:
```shell
./tests/run_tests [filter]
```

An optional `[filter]` can be used to run only a subset among available test
cases.

It is possible to specify the shell to use to run tests with `MODE` environment
variable. Possible values are:
- `bash` (default), to validate Bash compatibility,
- `zsh`, to validate ZSH compatibility.

::: warning
Every test should pass successfully with Bash and ZSH.
:::

Verbosity can be set through `VERBOSE` environment variable, possible values:
- 0: minimal output, test cases logs are sent to files (default),
- 1: same as 0, but in case of error failed test cases logs are displayed,
- 2: all logs are displayed.

Example:
```shell
VERBOSE=1 MODE=zsh ./tests/run_tests test_bb_set_current_project
```

When running tests, some temporary files are created:
- `tests/workspace`: temporary project copies used by tests, automatically cleaned up before every test.
- `log`: tests log output.
- `run`: test suite runtime ressources.

### Test data

Data is available for testing, and its structure is detailed below.

#### Fixture repositories

Test fixture repositories are stored as **git bundles** in `tests/bundles/`. They are reconstructed on demand by `tests/repositories/setup.sh`, which is called automatically at the start of every `./tests/run_tests` invocation. The reconstructed repos land in `tests/repositories/` (gitignored).

There are two kinds of fixtures:

- **Project fixtures** (`foo_project`, `bar_project`, `projects`): working-copy git repositories with a `.bbx/` profile directory. From test cases, `bb_use_test_project <fixture>` copies the fixture into the test workspace and sets it as the current project.
- **Remote package/tool repos** (`tests/repositories/remote/*.git`): bare git repositories used as clone sources. Package definitions reference them via `${BB_TEST_REPOSITORY_URI}`, which resolves to `file://${BB_DIR}/tests/repositories/remote`.

#### Modifying a fixture repository

When a test requires a change to a fixture (new file, new branch, updated content):

**1. Ensure the fixture repos exist:**
```shell
./tests/repositories/setup.sh
```

**2. Make your changes inside the reconstructed repo:**
```shell
# Working-copy fixture (foo_project, bar_project, projects):
cd tests/repositories/foo_project
git commit -am "My change"

# Bare remote repo — apply changes via a temporary working copy:
git clone tests/repositories/remote/foo_package.git /tmp/foo_package_work
cd /tmp/foo_package_work
# ... make changes, commit ...
git push
```

**3. Regenerate the bundle:**
```shell
# Working-copy fixture:
git -C tests/repositories/foo_project bundle create tests/bundles/foo_project.bundle --all

# Bare remote repo:
git -C tests/repositories/remote/foo_package.git bundle create tests/bundles/remote_foo_package.bundle --all
```

**4. Commit the updated bundle to BuildBox.**

The bundle names follow the convention: `<fixture_name>.bundle` for project fixtures and `remote_<repo_name>.bundle` for remote repos.

#### Tools

| Tool name | Location in packages repository | Repository | Tags | Provide load/unload scripts | Provide binaries | Provide ressources | Provide cleanup hook |
|---|---|---|---|---|---|---|---|
| foo_tool | / | Git | 1.0.0 1.0.1 1.0.2 | yes | yes | yes | >=1.0.1 |
| bar_tool | /subdir | Git |  | no | yes | yes | no |
| baz_tool | / | Git |  | yes | no | no | no |
| qux_tool | / | Git |  | yes (failing) | no | no | no |

#### Packages

| Package name | Location in packages repository | Repository | Tags / branches | Build mode |
|---|---|---|---|---|
| foo_package | / | Git | 1.0 branch/with/slashes | Prebuilt |
| foo_http_package | / | HTTP | 1.0 | Prebuilt |
| bar_package | / | Git | 1.0.0 rb-1.0.0 | Autotools |
| baz_package | / | Git |  | Make |
| qux_package | / | Git |  | Custom |
| quux_package | /subdir | Git |  | Prebuilt |
| corge_package | / | Git |  | Prebuilt |
| grault_package (alias to foo_package) | / | Git | 1.0 | (unsupported) |
| garply_package (alias to foo_package) | / | (unsupported) | 1.0 | Autotools |

#### Projects

##### foo_project

| Target | Tools | Packages | Variables |
|---|---|---|---|
| foo |  | foo_package<br />bar_package |  |
| bar (default) | foo_tool@1.0.2<br />bar_tool<br />baz_tool | foo_package@1.0<br />bar_package<br />corge_package<br />subdir/quux_package<br />foo_http_package-1.0 | VAR_FOO<br />VAR_BAR |

##### bar_project

| Target | Tools | Packages | Variables |
|---|---|---|---|
| foo |  | foo_package qux_package |  |
| bar |  | foo_package@1.0 |  |
| baz | foo_tool qux_tool | foo_package<br />grault_package<br />garply_package |  |
