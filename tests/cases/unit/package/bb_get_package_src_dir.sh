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

function test_bb_get_package_src_dir {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	# Cloned package
	bb_clone_package "foo_package@1.0"
	asserteq $? 0
	src_dir=$(bb_get_package_src_dir "foo_package@1.0")
	asserteq $? 0
	assertd "${src_dir}"
	assertf "${src_dir}/README"
	# Not cloned package
	src_dir=$(bb_get_package_src_dir "bar_package")
	assertne $? 0
	# Non existing package
	src_dir=$(bb_get_package_src_dir "unknown")
	assertne $? 0
	# Packages with revision containing '/'
	bb_clone_package "foo_package@branch/with/slashes"
	asserteq $? 0
	src_dir=$(bb_get_package_src_dir "foo_package@branch/with/slashes")
	asserteq $? 0
	assertd "${src_dir}"
	assertf "${src_dir}/README"
}
bb_declare_test test_bb_get_package_src_dir

