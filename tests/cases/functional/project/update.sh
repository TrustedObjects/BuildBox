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

## Tests for 'bbx project update' (project_update sbin command).
## In 2.x, update pulls changes into .bbx/ (if it is a submodule or has a remote).
## Since test fixtures don't have a remote, this tests the error path.

function test_project_update_no_project {
	out="$(bbx project update 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_update_no_project

function test_project_update_no_remote {
	# The test fixture has no remote, so update should report an error
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(bbx project update 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_update_no_remote
