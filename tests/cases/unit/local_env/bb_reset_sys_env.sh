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

function test_bb_reset_sys_env {
	path_orig="${PATH}"
	xdg_data_dirs_orig="${XDG_DATA_DIRS}"
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	assertne "${PATH}" "${path_orig}"
	assertne "${XDG_DATA_DIRS}" "${xdg_data_dirs_orig}"
	bb_reset_sys_env
	asserteq $? 0
	asserteq "${PATH}" "${path_orig}"
	asserteq "${XDG_DATA_DIRS}" "${xdg_data_dirs_orig}"
}
bb_declare_test test_bb_reset_sys_env
