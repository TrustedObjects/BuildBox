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

## @brief Sources using Git
## Clone backend to clone components using Git.

## @fn bb_git_clone
## Clone a Git repository in a target directory, and go to specified revision.
## Get submodules if needed.
## @param Repository URI
## @param Target directory (where to clone sources)
## @param Branch, tag or changeset to use
## @return 0 on success
function bb_git_clone () (
	git clone $1 $2
	[ $? -ne 0 ] && return 1
	cd $2
	git checkout $3
	[ $? -ne 0 ] && return 1
	git submodule init
	[ $? -ne 0 ] && return 1
	git submodule update
	return $?
)
bb_exportfn bb_git_clone
