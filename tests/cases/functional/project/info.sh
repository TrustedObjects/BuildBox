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

function test_project_info {
	bb_use_test_project foo_project
	asserteq $? 0

	info=$(bbx project info)
	asserteq $? 0
	info="$(unformat_string "${info}")"
	info="$(minspace_string "${info}")"
	info="$(echo "${info}" | tr -d ' ')"
	# check project name (basename of project dir)
	project_name=$(echo "${info}" | grep "Project:")
	asserteq $? 0
	assertn "${project_name}"
	# check path field
	project_path=$(echo "${info}" | grep "Path:")
	asserteq $? 0
	asserteq "$(echo "${project_path}" | cut -d ':' -f 2)" "${BB_PROJECT_DIR}"
	# profile status
	profile_status=$(echo "${info}" | grep "Profilestatus:")
	asserteq $? 0
	asserteq "$(echo "${profile_status}" | cut -d ':' -f 2)" "clean"
}
bb_declare_test test_project_info

function test_project_info_profile_modified {
	bb_use_test_project foo_project
	asserteq $? 0
	# change a profile file
	echo "fakepkg" >> ${BB_PROJECT_PROFILE_DIR}/packages.foo
	asserteq $? 0
	info=$(bbx project info)
	asserteq $? 0
	info="$(unformat_string "${info}")"
	info="$(minspace_string "${info}")"
	info="$(echo "${info}" | tr -d ' ')"
	profile_status=$(echo "${info}" | grep "Profilestatus:")
	asserteq $? 0
	asserteq "$(echo "${profile_status}" | cut -d ':' -f 2)" "modified"
}
bb_declare_test test_project_info_profile_modified

function test_project_info_no_err_log {
	bb_use_test_project foo_project
	asserteq $? 0
	out="$(bbx project info 2>&1 >/dev/null)"
	asserteq $? 0
	assertz "${out}"
}
bb_declare_test test_project_info_no_err_log

function test_project_info_no_project {
	out="$(bbx project info 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_info_no_project
