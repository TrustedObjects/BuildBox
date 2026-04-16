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

function test_bb_get_project_targets_formatted {
	bb_use_test_project foo_project
	asserteq $? 0
	targets=$(bb_get_project_targets_formatted 0)
	asserteq $? 0
	assertn "${targets}"
	asserteq $(echo -e "${targets}"|wc -l) 1
	targets=$(bb_get_project_targets_formatted 1)
	asserteq $? 0
	assertn "${targets}"
	asserteq $(echo -e "${targets}"|wc -l) 2
}
bb_declare_test test_bb_get_project_targets_formatted

function test_bb_get_project_targets_formatted_no_project {
	targets=$(bb_get_project_targets_formatted 0)
	assertne $? 0
}
bb_declare_test test_bb_get_project_targets_formatted_no_project
