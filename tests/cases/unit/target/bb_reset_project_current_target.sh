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

function test_bb_reset_project_current_target {
	bb_use_test_project foo_project
	assertq $? 0
	asserteq ${BB_TARGET} bar
	assertn ${BB_TARGET_DIR}
	assertn ${BB_TARGET_SRC_DIR}
	assertn ${BB_TARGET_BUILD_DIR}
	bb_reset_project_current_target
	asserteq $? 0
	assertz ${BB_TARGET}
	assertz ${BB_TARGET_DIR}
	assertz ${BB_TARGET_SRC_DIR}
	assertz ${BB_TARGET_BUILD_DIR}
}
bb_declare_test test_bb_reset_project_current_target

function test_bb_reset_project_current_target_current_target_not_set {
	assertz ${BB_TARGET}
	bb_reset_project_current_target
	asserteq $? 0
}
bb_declare_test test_bb_reset_project_current_target_current_target_not_set

