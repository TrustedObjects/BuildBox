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

## Tests for 'bbx clone' (project_clone sbin command).
## A profile is a standalone git repo. Cloning means creating a project
## directory and git-cloning the profile repo into <dir>/.bbx/.

function test_project_clone {
	local clone_dir="${BB_TEST_WORKSPACE}/cloned_foo_$$"
	bbx clone "file://${BB_DIR}/tests/repositories/remote/foo_profile.git" "${clone_dir}"
	asserteq $? 0
	assertd "${clone_dir}"
	assertd "${clone_dir}/.bbx"
	assertd "${clone_dir}/.bbx/.git"
	assertf "${clone_dir}/.bbx/target.foo"
	assertf "${clone_dir}/.bbx/target.bar"
	assertnd "${clone_dir}/.git"
	assertnd "${clone_dir}/src"
	assertnd "${clone_dir}/foo"
	assertnd "${clone_dir}/bar"
	# state written immediately so shell plugin shows target without container start
	assertf "${clone_dir}/state"
	local stored_target
	stored_target=$(cat "${clone_dir}/state")
	assertn "${stored_target}"
}
bb_declare_test test_project_clone

function test_project_clone_no_err_log {
	local clone_dir="${BB_TEST_WORKSPACE}/cloned_noerr_$$"
	out=$(bbx clone "file://${BB_DIR}/tests/repositories/remote/foo_profile.git" "${clone_dir}" 2>&1 >/dev/null)
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_project_clone_no_err_log

function test_project_clone_bad_url {
	out="$(bbx clone "file:///does_not_exist_repo_$$" 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_clone_bad_url

function test_project_clone_with_branch {
	local remote_dir="${BB_TEST_WORKSPACE}/remote_clone_branch_$$"
	git clone --bare --local "file://${BB_DIR}/tests/repositories/remote/foo_profile.git" "${remote_dir}" 2>/dev/null
	git -C "${remote_dir}" branch dev
	local clone_dir="${BB_TEST_WORKSPACE}/cloned_branch_$$"
	bbx clone -b dev "file://${remote_dir}" "${clone_dir}"
	asserteq $? 0
	assertd "${clone_dir}/.bbx/.git"
	local branch
	branch=$(git -C "${clone_dir}/.bbx" rev-parse --abbrev-ref HEAD)
	asserteq "${branch}" "dev"
	rm -rf "${remote_dir}"
}
bb_declare_test test_project_clone_with_branch

function test_project_clone_bad_branch {
	local clone_dir="${BB_TEST_WORKSPACE}/cloned_bad_branch_$$"
	out=$(bbx clone -b nonexistent_branch_$$ "file://${BB_DIR}/tests/repositories/remote/foo_profile.git" "${clone_dir}" 2>&1 >/dev/null)
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_clone_bad_branch

function test_project_clone_branch_missing_arg {
	out=$(bbx clone --branch 2>&1)
	assertne $? 0
}
bb_declare_test test_project_clone_branch_missing_arg
