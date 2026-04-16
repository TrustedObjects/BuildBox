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

function test_bb_package_is_modified {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_clone_package "foo_package@1.0"
	asserteq $? 0
	assertd "${BB_TARGET_SRC_DIR}/foo_package@1.0"
	bb_package_is_modified "foo_package@1.0"
	asserteq $? 0
	echo "Modification" >> "${BB_TARGET_SRC_DIR}/foo_package@1.0/README"
	asserteq $? 0
	bb_package_is_modified "foo_package@1.0"
	asserteq $? 1
}
bb_declare_test test_bb_package_is_modified

function test_bb_package_is_modified_unknown {
	bb_package_is_modified "unknown"
	asserteq $? 2
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	bb_package_is_modified "unknown"
	asserteq $? 2
	# Unable to know if an HTTP package has been modified
	bb_clone_package "foo_http_package-1.0"
	asserteq $? 0
	assertd "${BB_TARGET_SRC_DIR}/foo_http_package-1.0"
	bb_package_is_modified "foo_http_package-1.0"
	asserteq $? 2
	echo "Modification" >> "${BB_TARGET_SRC_DIR}/foo_http_package-1.0/README"
	asserteq $? 0
	bb_package_is_modified "foo_http_package-1.0"
	asserteq $? 2
}
bb_declare_test test_bb_package_is_modified_unknown

