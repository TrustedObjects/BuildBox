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

function test_bb_project_get_tag {
	bb_use_test_project foo_project
	asserteq $? 0
	# Create a tag on the profile git repo
	git -C "${BB_PROJECT_PROFILE_DIR}" tag "foo_project-1.0" HEAD
	tag=$(bb_project_get_tag)
	asserteq $? 0
	asserteq "${tag}" "foo_project-1.0"
}
bb_declare_test test_bb_project_get_tag

function test_bb_project_get_tag_ignores_args {
	bb_use_test_project foo_project
	asserteq $? 0
	git -C "${BB_PROJECT_PROFILE_DIR}" tag "foo_project-2.0" HEAD
	# Arguments must be silently ignored; result is always from BB_PROJECT_PROFILE_DIR
	tag=$(bb_project_get_tag "ignored_arg" 1)
	asserteq $? 0
	asserteq "${tag}" "foo_project-2.0"
}
bb_declare_test test_bb_project_get_tag_ignores_args
