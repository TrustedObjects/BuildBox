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
## In 2.x a project is a standalone git repo with .bbx/. Cloning means
## git-cloning such a repo. The local fixture repos are used as remotes.

function test_project_clone {
	local clone_dir="${BB_TEST_WORKSPACE}/cloned_foo_$$"
	bbx clone "file://${BB_DIR}/tests/repositories/foo_project" "${clone_dir}"
	asserteq $? 0
	assertd "${clone_dir}"
	assertd "${clone_dir}/.bbx"
	assertf "${clone_dir}/.bbx/target.foo"
	assertf "${clone_dir}/.bbx/target.bar"
	assertnd "${clone_dir}/src"
	assertnd "${clone_dir}/foo"
	assertnd "${clone_dir}/bar"
}
bb_declare_test test_project_clone

function test_project_clone_no_err_log {
	local clone_dir="${BB_TEST_WORKSPACE}/cloned_noerr_$$"
	out=$(bbx clone "file://${BB_DIR}/tests/repositories/foo_project" "${clone_dir}" 2>&1 >/dev/null)
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
