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

function test_bb_find_matching_packages {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	packages=$(bb_find_matching_packages 0 "package")
	asserteq $? 0
	asserteq $(echo "${packages}"|wc -l) 5
	echo ${packages}|grep "foo_package"
	asserteq $? 0
	echo ${packages}|grep "corge_package"
	asserteq $? 0
	echo ${packages}|grep "subdir/quux_package"
	asserteq $? 0
	packages=$(bb_find_matching_packages 0 "foo")
	asserteq $? 0
	asserteq $(echo "${packages}"|wc -l) 2 # foo_package, foo_http_package
	echo ${packages}|grep "foo"
	asserteq $? 0
}
bb_declare_test test_bb_find_matching_packages

function test_bb_find_matching_packages_no_match {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	packages=$(bb_find_matching_packages 0 "nomatch")
	asserteq $? 0
	assertz "${packages}"
}
bb_declare_test test_bb_find_matching_packages_no_match

function test_bb_find_matching_packages_target_not_set {
	bb_find_matching_packages 0 "foo"
	assertne $? 0
}
bb_declare_test test_bb_find_matching_packages_target_not_set

function test_bb_find_matching_packages_order {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar ## 2.x
	asserteq $? 0
	# Without options
	packages=$(bb_find_matching_packages 0 "package")
	asserteq "${packages}" "foo_package@1.0
bar_package
corge_package
subdir/quux_package
foo_http_package-1.0"
	# With options
	packages=$(bb_find_matching_packages 1 "package")
	asserteq "${packages}" "foo_package@1.0
bar_package: +ressource1_install
corge_package
subdir/quux_package
foo_http_package-1.0"
	# Subset without options
	packages=$(bb_find_matching_packages 0 "foo")
	asserteq "${packages}" "foo_package@1.0
foo_http_package-1.0"
	# Subset with options
	packages=$(bb_find_matching_packages 1 "foo")
	asserteq "${packages}" "foo_package@1.0
foo_http_package-1.0"
	# Multiple filters without options
	packages=$(bb_find_matching_packages 0 "foo" "bar")
	asserteq "${packages}" "foo_package@1.0
bar_package
foo_http_package-1.0"
	# Multiple filters with options
	packages=$(bb_find_matching_packages 1 "bar" "foo")
	asserteq "${packages}" "foo_package@1.0
bar_package: +ressource1_install
foo_http_package-1.0"
}
bb_declare_test test_bb_find_matching_packages_order

