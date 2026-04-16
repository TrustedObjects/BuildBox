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

function test_bb_get_packages_with_options {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	packages=$(bb_get_packages_with_options bar)
	asserteq $? 0
	asserteq $(echo "${packages}"|wc -l) 5
	echo ${packages}|grep "foo_package@1\.0"
	asserteq $? 0
	echo ${packages}|grep "bar_package: +ressource1_install"
	asserteq $? 0
	echo ${packages}|grep "corge_package"
	asserteq $? 0
	echo ${packages}|grep "subdir/quux_package"
	asserteq $? 0
}
bb_declare_test test_bb_get_packages_with_options

function test_bb_get_packages_with_options_project_not_set {
	packages=$(bb_get_packages_with_options bar)
	assertne $? 0
}
bb_declare_test test_bb_get_packages_with_options_project_not_set

function test_bb_get_packages_with_options_non_existing_target {
	bb_use_test_project foo_project
	asserteq $? 0
	packages=$(bb_get_packages_with_options doesnotexist)
	assertne $? 0
}
bb_declare_test test_bb_get_packages_with_options_non_existing_target

