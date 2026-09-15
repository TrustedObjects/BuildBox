# This file is part of BuildBox project
# Copyright (C) 2020-2026 Trusted Objects

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2, as published by the Free Software Foundation.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, see
# <https://www.gnu.org/licenses/>.

## Tests for 'bbx project build', 'bbx project test' and 'bbx project dist',
## which run over every target of the project and report per target.

# Add a target which can not be built, its packages list naming a package
# which does not exist
# @param Target name
function declare_broken_target {
	printf 'nosuchpackage\n' > "${BB_PROJECT_PROFILE_DIR}/packages.${1}"
	printf 'CPU=x86\nPACKAGES=packages.%s\n' "${1}" \
		> "${BB_PROJECT_PROFILE_DIR}/target.${1}"
}

function test_project_build {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(bbx project build)
	asserteq $? 0
	# Every target of the project is built
	assertf ${BB_PROJECT_DIR}/foo/build/bin/bar_package
	assertf ${BB_PROJECT_DIR}/bar/build/bin/bar_package
	# One report line per target, with the build warnings count
	assert "echo '${out}' | grep -qE 'foo .*ok'"
	assert "echo '${out}' | grep -qE 'bar .*ok'"
	assert "echo '${out}' | grep -q 'Project build report'"
	assert "echo '${out}' | grep -q 'WARNINGS'"
}
bb_declare_test test_project_build

function test_project_build_restores_current_target {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target foo
	asserteq $? 0
	bbx project build > /dev/null
	asserteq $? 0
	# The command switches targets, the one in use must come back
	asserteq "$(cat ${BB_PROJECT_DIR}/state)" "foo"
}
bb_declare_test test_project_build_restores_current_target

function test_project_build_continues_on_error {
	bb_use_test_project foo_project
	asserteq $? 0
	declare_broken_target broken
	out=$(bbx project build 2>&1)
	# A failing target does not stop the others, but the command fails
	assertne $? 0
	assert "echo '${out}' | grep -qE 'broken .*failed'"
	assert "echo '${out}' | grep -qE 'foo .*ok'"
	assert "echo '${out}' | grep -qE 'bar .*ok'"
	assert "echo '${out}' | grep -q 'target(s) failed'"
	# The other targets were really built
	assertf ${BB_PROJECT_DIR}/foo/build/bin/bar_package
	assertf ${BB_PROJECT_DIR}/bar/build/bin/bar_package
}
bb_declare_test test_project_build_continues_on_error

function test_project_build_stop_on_error {
	bb_use_test_project foo_project
	asserteq $? 0
	# 'foo' comes first: breaking it leaves a target behind
	printf 'nosuchpackage\n' > "${BB_PROJECT_PROFILE_DIR}/packages.foo"
	out=$(bbx project build --stop-on-error 2>&1)
	assertne $? 0
	assert "echo '${out}' | grep -qE 'foo .*failed'"
	assert "echo '${out}' | grep -q 'Stopped on error'"
	# Targets left untouched are reported, not silently dropped
	assert "echo '${out}' | grep -qE 'bar .*not run'"
	# And 'bar' was really not built
	assertnf ${BB_PROJECT_DIR}/bar/build/bin/bar_package
}
bb_declare_test test_project_build_stop_on_error

function test_project_test {
	bb_use_test_project foo_project
	asserteq $? 0
	bbx project build > /dev/null
	asserteq $? 0
	out=$(bbx project test)
	asserteq $? 0
	# 'foo' defines no TESTS: skipped rather than failed
	assert "echo '${out}' | grep -qE 'foo .*skipped'"
	assert "echo '${out}' | grep -qE 'bar .*ok'"
	assert "echo '${out}' | grep -q 'Project test report'"
	# Build warnings are a build notion, the column is not shown
	assert "! echo '${out}' | grep -q 'WARNINGS'"
}
bb_declare_test test_project_test

function test_project_dist {
	bb_use_test_project foo_project
	asserteq $? 0
	bbx project build > /dev/null
	asserteq $? 0
	out=$(bbx project dist)
	asserteq $? 0
	# 'foo' defines no DIST: skipped
	assert "echo '${out}' | grep -qE 'foo .*skipped'"
	assert "echo '${out}' | grep -qE 'bar .*ok'"
	assert "echo '${out}' | grep -q 'Project dist report'"
}
bb_declare_test test_project_dist

function test_project_build_help {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(bbx project build --help)
	asserteq $? 0
	assert "echo '${out}' | grep -q 'stop-on-error'"
	out=$(bbx project test --help)
	asserteq $? 0
	assert "echo '${out}' | grep -q 'TESTS'"
}
bb_declare_test test_project_build_help

function test_project_build_project_not_set {
	out="$(bbx project build 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_build_project_not_set

function test_project_clone_targets {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(bbx project clone)
	asserteq $? 0
	# Sources of every target are fetched
	assertl "${BB_PROJECT_DIR}/foo/src/bar_package"
	assertl "${BB_PROJECT_DIR}/bar/src/foo_package@1.0"
	assert "echo '${out}' | grep -qE 'foo .*ok'"
	assert "echo '${out}' | grep -qE 'bar .*ok'"
	assert "echo '${out}' | grep -q 'Project clone report'"
	# Cloning produces no build warning, the column is not shown
	assert "! echo '${out}' | grep -q 'WARNINGS'"
	# No target is ever skipped: they can all be cloned
	assert "! echo '${out}' | grep -q 'skipped'"
}
bb_declare_test test_project_clone_targets

function test_project_clone_targets_forwards_options {
	bb_use_test_project foo_project
	asserteq $? 0
	bbx project clone > /dev/null
	asserteq $? 0
	# '-u' reaches 'target clone', which updates instead of leaving as is
	out=$(bbx project clone -u)
	asserteq $? 0
	assert "echo '${out}' | grep -qE 'up to date|updated'"
}
bb_declare_test test_project_clone_targets_forwards_options

function test_project_clone_targets_continues_on_error {
	bb_use_test_project foo_project
	asserteq $? 0
	declare_broken_target broken
	out=$(bbx project clone 2>&1)
	assertne $? 0
	assert "echo '${out}' | grep -qE 'broken .*failed'"
	assert "echo '${out}' | grep -qE 'foo .*ok'"
	# The other targets were really fetched
	assertl "${BB_PROJECT_DIR}/foo/src/bar_package"
}
bb_declare_test test_project_clone_targets_continues_on_error

function test_project_not_excludes_target {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(bbx project clone -n foo)
	asserteq $? 0
	assert "echo '${out}' | grep -qE 'foo .*excluded'"
	assert "echo '${out}' | grep -qE 'bar .*ok'"
	# An excluded target is really left alone
	assertnd "${BB_PROJECT_DIR}/foo/src"
	assertd "${BB_PROJECT_DIR}/bar/src"
}
bb_declare_test test_project_not_excludes_target

function test_project_not_is_repeatable {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(bbx project build --not foo --not bar)
	asserteq $? 0
	assert "echo '${out}' | grep -qE 'foo .*excluded'"
	assert "echo '${out}' | grep -qE 'bar .*excluded'"
	assertnd "${BB_PROJECT_DIR}/foo/src"
	assertnd "${BB_PROJECT_DIR}/bar/src"
}
bb_declare_test test_project_not_is_repeatable

function test_project_not_unknown_target_warns {
	bb_use_test_project foo_project
	asserteq $? 0
	err=$(bbx project clone -n nosuchtarget 2>&1 >/dev/null)
	# A typo must be visible, without stopping the run
	asserteq $? 0
	assert "echo '${err}' | grep -q 'nosuchtarget'"
	assertd "${BB_PROJECT_DIR}/foo/src"
}
bb_declare_test test_project_not_unknown_target_warns

function test_project_not_without_value_fails {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(bbx project clone --not 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_not_without_value_fails

function test_project_output_layout {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(bbx project clone)
	asserteq $? 0
	# The first line names a target: no blank line opens the output
	asserteq "$(echo "${out}" | head -n 1 | sed 's/\x1b\[[0-9;]*m//g')" "foo"
	# The target name is given in blue, without '=' decoration
	assert "echo '${out}' | head -n 1 | grep -q '34m'"
	assert "! echo '${out}' | grep -q '==='"
}
bb_declare_test test_project_output_layout

function test_project_clone_targets_help_tells_update {
	bb_use_test_project foo_project
	asserteq $? 0
	out=$(bbx project clone --help)
	asserteq $? 0
	assert "echo '${out}' | grep -qe '--update'"
}
bb_declare_test test_project_clone_targets_help_tells_update
