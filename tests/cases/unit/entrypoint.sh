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

# Test buildbox_utils.sh sourcing

function entrypoint_init() (
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
)

function test_buildbox_utils_sourcing {
	entrypoint_init
	# entrypoint_init is run in a subshell, so the environment should not be modified
	assertz "${BB_PROJECT_DIR}"
	assertz "${BB_TARGET}"
	# cd into the project workspace where entrypoint_init wrote state=bar
	cd "${BB_TEST_WORKSPACE}/foo_project"
	source buildbox_utils.sh
	asserteq $? 0
	asserteq "${BB_PROJECT_DIR}" "${BB_TEST_WORKSPACE}/foo_project"
	asserteq "${BB_TARGET}" "bar"
}
bb_declare_test test_buildbox_utils_sourcing
