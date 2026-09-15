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

## Tests for 'bbx project update' (project_update sbin command).
## In 2.x, update pulls changes into .bbx/ (if it is a submodule or has a remote).
## Since test fixtures don't have a remote, this tests the error path.

function test_project_update_no_project {
	out="$(bbx project update 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_update_no_project

function test_project_update_no_remote {
	# The test fixture has no remote, so update should report an error
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(bbx project update 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_update_no_remote

## A project whose profile has a remote, so that 'project update' has something
## to update, unlike the fixtures used above
## @print The project directory
function setup_updatable_project {
	local dir="${BB_TEST_WORKSPACE}/upd_project_$$"
	rm -rf "${dir}"
	bbx clone "file://${BB_DIR}/tests/repositories/remote/foo_profile.git" \
		"${dir}" > /dev/null 2>&1
	echo "${dir}"
}

function test_project_update_all {
	dir=$(setup_updatable_project)
	bb_set_current_project "${dir}"
	asserteq $? 0
	out=$(bbx project update -a)
	asserteq $? 0
	# The profile first, then the sources of every target
	assert "echo '${out}' | grep -q 'Project profile updated'"
	assert "echo '${out}' | grep -q 'Project clone report'"
	assert "echo '${out}' | grep -qE 'foo .*ok'"
	assert "echo '${out}' | grep -qE 'bar .*ok'"
	assertl "${dir}/foo/src/bar_package"
	assertl "${dir}/bar/src/foo_package@1.0"
}
bb_declare_test test_project_update_all

function test_project_update_all_long_option {
	dir=$(setup_updatable_project)
	bb_set_current_project "${dir}"
	asserteq $? 0
	out=$(bbx project update --all)
	asserteq $? 0
	assert "echo '${out}' | grep -q 'Project clone report'"
}
bb_declare_test test_project_update_all_long_option

function test_project_update_without_all_keeps_sources {
	dir=$(setup_updatable_project)
	bb_set_current_project "${dir}"
	asserteq $? 0
	out=$(bbx project update)
	asserteq $? 0
	assert "echo '${out}' | grep -q 'Project profile updated'"
	# Without '-a' the sources are none of its business
	assert "! echo '${out}' | grep -q 'Project clone report'"
	assertnd "${dir}/foo/src"
	assertnd "${dir}/src"
}
bb_declare_test test_project_update_without_all_keeps_sources

function test_project_update_unknown_option {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(bbx project update --nope 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_update_unknown_option

function test_project_update_help {
	out=$(bbx project update --help)
	asserteq $? 0
	assert "echo '${out}' | grep -qe '--all'"
}
bb_declare_test test_project_update_help
