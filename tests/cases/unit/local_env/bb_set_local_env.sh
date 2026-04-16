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

function test_bb_set_local_env {
	bb_use_test_project foo_project bar
	asserteq $? 0
	# Only cloned tools are taken into account by local env
	bb_clone_tool "foo_tool@1.0.2"
	asserteq $? 0
	bb_set_local_env
	asserteq $? 0
	# Checks
	# path
	assert_in_path_list "${BB_TARGET_BUILD_DIR}/bin" "${PATH}"
	assert_in_path_list "${BB_TARGET_BUILD_DIR}/sbin" "${PATH}"
	assert_in_path_list "${BB_TOOLS_DIR}/foo_tool@1.0.2/bin" "${PATH}"
	assert_in_path_list "${BB_TOOLS_DIR}/foo_tool@1.0.2/sbin" "${PATH}"
	# pkg-config path
	assert_in_path_list "${BB_TARGET_BUILD_DIR}/lib/pkgconfig" "${PKG_CONFIG_PATH}"
	assert_in_path_list "${BB_TARGET_BUILD_DIR}/share/pkgconfig" "${PKG_CONFIG_PATH}"
	assert_in_path_list "${BB_TOOLS_DIR}/foo_tool@1.0.2/lib/pkgconfig" "${PKG_CONFIG_PATH}"
	assert_in_path_list "${BB_TOOLS_DIR}/foo_tool@1.0.2/share/pkgconfig" "${PKG_CONFIG_PATH}"
	# cflags
	assertn "${CFLAGS}"
	# ldflags
	assertn "${LDFLAGS}"
	# ld library path
	assert_in_path_list "${BB_TARGET_BUILD_DIR}/lib" "${LD_LIBRARY_PATH}"
	assert_in_path_list "${BB_TOOLS_DIR}/foo_tool@1.0.2/lib" "${LD_LIBRARY_PATH}"
	# aclocal path
	assert_in_path_list "${BB_TARGET_BUILD_DIR}/share/aclocal" "${ACLOCAL_PATH}"
	assert_in_path_list "${BB_TOOLS_DIR}/foo_tool@1.0.2/share/aclocal" "${ACLOCAL_PATH}"
	# XDG data dirs
	assert_in_path_list "${BB_TARGET_BUILD_DIR}/share" "${XDG_DATA_DIRS}"
	assert_in_path_list "${BB_TOOLS_DIR}/foo_tool@1.0.2/share" "${XDG_DATA_DIRS}"
	# prefix
	assertn "${PREFIX}"
	asserteq "${PREFIX}" "${BB_TARGET_BUILD_DIR}"
	# Python
	assert_in_path_list "${BB_TARGET_BUILD_DIR}/bin" "${PYTHONPATH}"
	assert_in_path_list "${BB_TARGET_BUILD_DIR}/lib/python/site-packages" "${PYTHONPATH}"
	assert_in_path_list "${BB_TOOLS_DIR}/foo_tool@1.0.2/bin" "${PYTHONPATH}"
	assert_in_path_list "${BB_TOOLS_DIR}/foo_tool@1.0.2/lib/python/site-packages" "${PYTHONPATH}"
	# misc.
	assertn "${CHOST}"
	assertn "${CPU}"
	assertn "${CPUDEF}"
	assertn "${CPU_FAMILY}"
	assertn "${CPU_DESCRIPTION}"
}
bb_declare_test test_bb_set_local_env

function test_bb_set_local_env_project_not_set {
	bb_set_local_env
	assertne $? 0
}
bb_declare_test test_bb_set_local_env_project_not_set

function test_bb_set_local_env_target_not_set {
	bb_use_test_project foo_project
	asserteq $? 0
	# Clear target and PREFIX to test the no-target early-return path.
	# bb_set_current_project always sets a default target when default_target
	# symlink exists, so we must unset manually.
	unset BB_TARGET
	unset PREFIX
	bb_set_local_env
	asserteq $? 0
	assertz "${PREFIX}"
}
bb_declare_test test_bb_set_local_env_target_not_set

