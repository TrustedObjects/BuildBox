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

function test_bb_package_supports_sources_sharing_prebuilt {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_package_supports_sources_sharing "foo_package@1.0"
	asserteq $? 1
}
bb_declare_test test_bb_package_supports_sources_sharing_prebuilt

function test_bb_package_supports_sources_sharing_autotools {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_package_supports_sources_sharing "bar_package"
	asserteq $? 1
}
bb_declare_test test_bb_package_supports_sources_sharing_autotools

function test_bb_package_supports_sources_sharing_make {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_package_supports_sources_sharing "baz_package"
	asserteq $? 0
}
bb_declare_test test_bb_package_supports_sources_sharing_make

function test_bb_package_supports_sources_sharing_custom {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target foo
	asserteq $? 0
	bb_package_supports_sources_sharing "baz_package"
	asserteq $? 0
}
bb_declare_test test_bb_package_supports_sources_sharing_custom

function test_bb_package_supports_sources_sharing_unknown {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	bb_package_supports_sources_sharing "unknown"
	asserteq $? 0
}
bb_declare_test test_bb_package_supports_sources_sharing_unknown

function test_bb_package_supports_sources_sharing_unsupported_build_mode {
	bb_use_test_project bar_project
	asserteq $? 0
	bb_set_project_current_target baz
	asserteq $? 0
	bb_package_supports_sources_sharing "grault_package"
	asserteq $? 0
}
bb_declare_test test_bb_package_supports_sources_sharing_unsupported_build_mode

function test_bb_package_supports_sources_sharing_explicit_disabled {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	printf 'SRC_PROTO=local\nSRC_BUILD=autotools\nSRC_SUPPORTS_SHARING=0\n' \
		> "${BB_PROJECT_PROFILE_DIR}/packages/sharing_disabled_package"
	bb_package_supports_sources_sharing "sharing_disabled_package"
	asserteq $? 0
}
bb_declare_test test_bb_package_supports_sources_sharing_explicit_disabled

function test_bb_package_supports_sources_sharing_explicit_enabled {
	bb_use_test_project foo_project
	asserteq $? 0
	bb_set_project_current_target bar
	asserteq $? 0
	printf 'SRC_PROTO=local\nSRC_BUILD=autotools\nSRC_SUPPORTS_SHARING=1\n' \
		> "${BB_PROJECT_PROFILE_DIR}/packages/sharing_enabled_package"
	bb_package_supports_sources_sharing "sharing_enabled_package"
	asserteq $? 1
}
bb_declare_test test_bb_package_supports_sources_sharing_explicit_enabled

