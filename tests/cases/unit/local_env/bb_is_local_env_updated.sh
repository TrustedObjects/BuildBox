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

function test_bb_is_local_env_updated {
	bb_use_test_project foo_project bar
	asserteq $? 0
	bb_set_local_env
	asserteq $? 0
	# After bb_set_local_env, bb_local_env_updated was called internally
	bb_is_local_env_outdated
	asserteq $? 0
	# Change target to make outdated
	export BB_TARGET="foo"
	bb_is_local_env_outdated
	assertne $? 0
	# Assume environment is updated (this is not really the case)
	bb_local_env_updated
	# Check environment up-to-date
	bb_is_local_env_outdated
	asserteq $? 0
}
bb_declare_test test_bb_is_local_env_updated
