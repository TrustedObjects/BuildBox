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

## Tests for 'bbx migrate' (project_migrate sbin command).
## Uses the local legacy test repository as the "remote" URL (file://).
## The legacy test repo at tests/repositories/remote/projects.git has branches
## 'foo_project' and 'bar_project' that represent 1.x project profiles.

function test_project_migrate_foo {
	local legacy_url="file://${BB_DIR}/tests/repositories/remote/projects.git"
	local output="${BB_TEST_WORKSPACE}/migrated_foo_$$"

	project_migrate --url "${legacy_url}" --branch foo_project --output "${output}"
	asserteq $? 0

	# Result is a git repository
	assertd "${output}/.git"

	# Profile content has been moved into .bbx/
	assertd "${output}/.bbx"
	assertf "${output}/.bbx/target.foo"
	assertf "${output}/.bbx/target.bar"
	assertf "${output}/.bbx/packages.foo"
	assertf "${output}/.bbx/packages.bar"
	assertf "${output}/.bbx/tools.bar"
	assertf "${output}/.bbx/bar_dist.sh"
	assertf "${output}/.bbx/bar_test.sh"
	assertl "${output}/.bbx/default_target"   # symlink kept

	# Packages is a submodule at .bbx/packages (gitlink, not a plain dir)
	entry_mode=$(git -C "${output}" ls-files -s -- .bbx/packages | awk '{print $1}')
	asserteq "${entry_mode}" "160000"

	# .gitmodules is at root and points to .bbx/packages
	assertf "${output}/.gitmodules"
	pkg_path=$(git config -f "${output}/.gitmodules" submodule.packages.path)
	asserteq "${pkg_path}" ".bbx/packages"

	# Nothing left at root except .git, .gitmodules, .gitignore
	local root_files
	root_files=$(git -C "${output}" ls-files | grep -v '^\.gitmodules$' | grep -v '^\.gitignore$' | grep -v '^\.bbx/')
	assertz "${root_files}"

	# .gitignore was created and covers expected directories
	assertf "${output}/.gitignore"
	asserteq $? 0
	grep -q "^src/$" "${output}/.gitignore"
	asserteq $? 0
	grep -q "^\.bbx/\.state$" "${output}/.gitignore"
	asserteq $? 0

	# Branch is master with no remote
	branch=$(git -C "${output}" rev-parse --abbrev-ref HEAD)
	asserteq "${branch}" "master"
	remote=$(git -C "${output}" remote)
	assertz "${remote}"

	# The project is usable with BuildBox 2.x (autodetect finds .bbx/)
	bb_set_current_project "${output}"
	asserteq $? 0
	asserteq "${BB_TARGET}" "bar"   # default_target -> target.bar
	targets=$(bb_get_project_targets | sort | tr '\n' ' ' | xargs)
	asserteq "${targets}" "bar foo"
}
bb_declare_test test_project_migrate_foo

function test_project_migrate_bar {
	local legacy_url="file://${BB_DIR}/tests/repositories/remote/projects.git"
	local output="${BB_TEST_WORKSPACE}/migrated_bar_$$"

	project_migrate --url "${legacy_url}" --branch bar_project --output "${output}"
	asserteq $? 0

	assertd "${output}/.bbx"
	assertf "${output}/.bbx/target.bar"
	# bar_project branch does not have foo target
	assertnf "${output}/.bbx/bar_dist.sh"  # bar_project branch has no dist script

	# Packages submodule at .bbx/packages
	entry_mode=$(git -C "${output}" ls-files -s -- .bbx/packages | awk '{print $1}')
	asserteq "${entry_mode}" "160000"
}
bb_declare_test test_project_migrate_bar

function test_project_migrate_output_already_exists {
	local output="${BB_TEST_WORKSPACE}/already_exists_$$"
	mkdir -p "${output}"
	out="$(project_migrate --url "file://${BB_DIR}/tests/repositories/remote/projects.git" \
		--branch foo_project --output "${output}" 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_migrate_output_already_exists

function test_project_migrate_bad_branch {
	local output="${BB_TEST_WORKSPACE}/bad_branch_$$"
	out="$(project_migrate --url "file://${BB_DIR}/tests/repositories/remote/projects.git" \
		--branch does_not_exist_branch --output "${output}" 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_migrate_bad_branch

function test_project_migrate_bad_url {
	local output="${BB_TEST_WORKSPACE}/bad_url_$$"
	out="$(project_migrate --url "file:///does_not_exist_repo_$$" \
		--branch foo_project --output "${output}" 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_migrate_bad_url

function test_project_migrate_no_args {
	out="$(project_migrate 2>&1 >/dev/null)"
	assertne $? 0
	assertn "${out}"
}
bb_declare_test test_project_migrate_no_args
