#!/bin/bash
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

## Tests for 'bbx init' (project_init sbin command).

function test_project_init {
	local init_dir="${BB_TEST_WORKSPACE}/init_basic_$$"
	bbx init "${init_dir}"
	asserteq $? 0
	assertd "${init_dir}/.bbx"
	assertf "${init_dir}/.bbx/target.default"
	assertf "${init_dir}/.bbx/packages.default"
	assertl "${init_dir}/.bbx/default_target"
	assertd "${init_dir}/.bbx/packages"
	# .bbx/ is the git root; project dir itself is not a git repo
	assertd "${init_dir}/.bbx/.git"
	assertnd "${init_dir}/.git"
	# state written immediately so shell plugin shows target without container start
	assertf "${init_dir}/state"
	local stored_target
	stored_target=$(cat "${init_dir}/state")
	asserteq "${stored_target}" "default"
}
bb_declare_test test_project_init

function test_project_init_no_image_file {
	local init_dir="${BB_TEST_WORKSPACE}/init_no_image_$$"
	bbx init "${init_dir}"
	asserteq $? 0
	assertnf "${init_dir}/.bbx/image"
}
bb_declare_test test_project_init_no_image_file

function test_project_init_with_image {
	local init_dir="${BB_TEST_WORKSPACE}/init_image_$$"
	bbx init --image "mycompany/buildbox-custom:1.0" "${init_dir}"
	asserteq $? 0
	assertf "${init_dir}/.bbx/image"
	local stored_image
	stored_image=$(cat "${init_dir}/.bbx/image")
	asserteq "${stored_image}" "mycompany/buildbox-custom:1.0"
}
bb_declare_test test_project_init_with_image

function test_project_init_image_in_output {
	local init_dir="${BB_TEST_WORKSPACE}/init_image_out_$$"
	local out
	out=$(bbx init --image "mycompany/buildbox-custom:1.0" "${init_dir}")
	asserteq $? 0
	echo "${out}" | grep -q "Image:"
	asserteq $? 0
	echo "${out}" | grep -q "mycompany/buildbox-custom:1.0"
	asserteq $? 0
}
bb_declare_test test_project_init_image_in_output

function test_project_init_no_image_in_output {
	local init_dir="${BB_TEST_WORKSPACE}/init_no_image_out_$$"
	local out
	out=$(bbx init "${init_dir}")
	asserteq $? 0
	echo "${out}" | grep -qw "Image:"
	assertne $? 0
}
bb_declare_test test_project_init_no_image_in_output

function test_project_init_image_missing_arg {
	out=$(bbx init --image 2>&1)
	assertne $? 0
}
bb_declare_test test_project_init_image_missing_arg

function test_project_init_already_initialized {
	local init_dir="${BB_TEST_WORKSPACE}/init_twice_$$"
	bbx init "${init_dir}"
	asserteq $? 0
	out=$(bbx init "${init_dir}" 2>&1)
	assertne $? 0
	echo "${out}" | grep -qi "already"
	asserteq $? 0
}
bb_declare_test test_project_init_already_initialized
