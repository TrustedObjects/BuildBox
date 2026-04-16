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

function test_bb_set_current_project {
	local project_dir
	project_dir=$(bb_setup_test_project foo_project)
	asserteq $? 0
	# Set project from path
	bb_set_current_project "${project_dir}"
	asserteq $? 0
	asserteq "${BB_PROJECT_DIR}" "${project_dir}"
	asserteq "${BB_PROJECT}" "$(basename "${project_dir}")"
	asserteq "${BB_PROJECT_PROFILE_DIR}" "${project_dir}/.bbx"
	asserteq "${BB_PROJECT_SRC_DIR}" "${project_dir}/src"
	# default_target in foo_project fixture is bar
	asserteq "${BB_TARGET}" "bar"
	# Set project again with explicit target
	bb_set_current_project "${project_dir}"
	asserteq $? 0
	bb_set_project_current_target foo
	asserteq $? 0
	asserteq "${BB_TARGET}" "foo"
}
bb_declare_test test_bb_set_current_project

function test_bb_set_current_project_invalid {
	bb_set_current_project "/tmp/does_not_exist_bbx_project_$$"
	assertne $? 0
}
bb_declare_test test_bb_set_current_project_invalid
