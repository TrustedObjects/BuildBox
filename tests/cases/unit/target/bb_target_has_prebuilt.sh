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


function test_bb_target_has_prebuilt {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	bb_put_fake_prebuilt > /dev/null
	asserteq $? 0
	bb_target_has_prebuilt
	asserteq $? 0
	assertn "$(grep "^rsync .*tester@prebuilt.test:/prebuilt/master/v1.0.0/bar.tar.xz" \
		"${BB_TEST_PREBUILT_SERVER_LOG}")"
}
bb_declare_test test_bb_target_has_prebuilt

function test_bb_target_has_prebuilt_none {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	out="$(bb_target_has_prebuilt 2>&1)"
	assertne $? 0
	assertz "${out}"
}
bb_declare_test test_bb_target_has_prebuilt_none

function test_bb_target_has_prebuilt_other_target {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	bb_put_fake_prebuilt > /dev/null
	asserteq $? 0
	bb_set_project_current_target foo
	asserteq $? 0
	bb_target_has_prebuilt
	assertne $? 0
}
bb_declare_test test_bb_target_has_prebuilt_other_target

function test_bb_target_has_prebuilt_other_tag {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_use_fake_prebuilt_server
	asserteq $? 0
	bb_put_fake_prebuilt > /dev/null
	asserteq $? 0
	# The prebuilt belongs to v1.0.0, the project is now past it
	bb_commit_test_project_profile
	asserteq $? 0
	bb_target_has_prebuilt
	assertne $? 0
}
bb_declare_test test_bb_target_has_prebuilt_other_tag
