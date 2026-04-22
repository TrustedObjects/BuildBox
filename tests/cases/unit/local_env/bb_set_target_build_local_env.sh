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

function test_bb_set_target_build_local_env {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target foo
	asserteq $? 0
	export BB_TARGET="bar"
	export BB_TARGET_BUILD_DIR="${BB_PROJECT_DIR}/bar/build"
	bb_set_target_build_local_env
	asserteq $? 0
	assertn "${CFLAGS}"
	assertn "${LDFLAGS}"
	assertn "${CHOST}"
	assertn "${CPU}"
	assertn "${CPUDEF}"
	assertn "${CPU_FAMILY}"
	assertn "${CPU_DESCRIPTION}"
	assertn "${PREFIX}"
	asserteq "${PREFIX}" "${BB_TARGET_BUILD_DIR}"
	assertn "${PATH}"
	assertn "${PKG_CONFIG_PATH}"
	assertn "${LD_LIBRARY_PATH}"
	assertn "${PYTHONPATH}"
	assertn "${ACLOCAL_PATH}"
	assertn "${XDG_DATA_DIRS}"
	# More detailed checks are performed in bb_set_local_env.sh
}
bb_declare_test test_bb_set_target_build_local_env

function test_bb_set_target_build_local_env_target_not_set {
	bb_set_target_build_local_env
	assertne $? 0
}
bb_declare_test test_bb_set_target_build_local_env_target_not_set
