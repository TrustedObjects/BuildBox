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

function test_bb_reset_current_project {
	bb_use_test_project foo_project
	asserteq $? 0
	assertn "${BB_PROJECT_DIR}"
	bb_reset_current_project
	asserteq $? 0
	assertz "${BB_PROJECT_DIR}"
	assertz "${BB_PROJECT_PROFILE_DIR}"
	assertz "${BB_PROJECT_SRC_DIR}"
	assertz "${BB_TARGET}"
	assertz "${BB_TARGET_DIR}"
	assertz "${BB_TARGET_SRC_DIR}"
	assertz "${BB_TARGET_BUILD_DIR}"
}
bb_declare_test test_bb_reset_current_project
