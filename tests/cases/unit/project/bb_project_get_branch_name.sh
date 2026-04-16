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

function test_bb_project_get_branch_name {
	bb_use_test_project foo_project
	asserteq $? 0
	name=$(bb_project_get_branch_name)
	asserteq $? 0
	# foo_project fixture has HEAD on its only commit (detached or main branch)
	assertn "${name}"
}
bb_declare_test test_bb_project_get_branch_name

function test_bb_project_get_branch_name_explicit_path {
	local project_dir
	project_dir=$(bb_setup_test_project foo_project)
	asserteq $? 0
	name=$(bb_project_get_branch_name "${project_dir}")
	asserteq $? 0
	assertn "${name}"
}
bb_declare_test test_bb_project_get_branch_name_explicit_path
