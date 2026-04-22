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

function test_bb_reset_local_env {
	path_orig="${PATH}"
	xdg_data_dirs_orig="${XDG_DATA_DIRS}"
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_reset_local_env
	asserteq $? 0
	# Check reset
	assertz "${CPU}"
	assertz "${CPUDEF}"
	assertz "${CHOST}"
	assertz "${CPU_FAMILY}"
	assertz "${PREFIX}"
	assertz "${PKG_CONFIG_PATH}"
	assertz "${CFLAGS}"
	assertz "${LD_LIBRARY_PATH}"
	assertz "${LDFLAGS}"
	assertz "${ACLOCAL_PATH}"
	assertz "${PYTHONPATH}"
	asserteq "${path_orig}" "${PATH}"
	asserteq "${xdg_data_dirs_orig}" "${XDG_DATA_DIRS}"
	env|grep -v "BB_TARGET_VAR_"
	asserteq $? 0
}
bb_declare_test test_bb_reset_local_env

