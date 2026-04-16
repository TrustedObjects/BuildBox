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

function test_bb_get_package_name_no_revision {
	# No revision
	name=$(bb_get_package_name_no_revision "package")
	asserteq "$name" "package"
	# Numeric revision after '-'
	name=$(bb_get_package_name_no_revision "package-1.2.3")
	asserteq "$name" "package"
	name=$(bb_get_package_name_no_revision "package-test-1.2.3")
	asserteq "$name" "package-test"
	# Revision after '@'
	name=$(bb_get_package_name_no_revision "package@1.2.3")
	asserteq "$name" "package"
	name=$(bb_get_package_name_no_revision "package-test@rev1.2.3b")
	asserteq "$name" "package-test"
}

bb_declare_test test_bb_get_package_name_no_revision
