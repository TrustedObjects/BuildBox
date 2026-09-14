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

## @fn bb_git_moved_tags
## Print the tags of a repository which do not designate the same commit
## upstream any more, one per line.
##
## Such a tag is the mark of a remote repository whose history changed, and it
## is what makes a fetch of the tags fail: Git refuses to overwrite a tag it
## already has. A tag which is not here yet is not one of them, it is simply
## fetched.
## @param Directory holding the repository
## @print The name of every tag which moved upstream, one per line
## @return 0 on success, else error
function bb_git_moved_tags () (
	local dir="${1}"
	cd "${dir}"
	[ $? -ne 0 ] && return 1
	local sha ref name here
	while read -r sha ref; do
		# A peeled reference (refs/tags/<name>^{}) says which commit an
		# annotated tag points at: the tag object itself is compared
		case "${ref}" in
			*"^{}") continue ;;
		esac
		name=${ref#refs/tags/}
		here=$(git rev-parse --verify --quiet "refs/tags/${name}")
		if [ -n "${here}" ] && [ "${here}" != "${sha}" ]; then
			echo "${name}"
		fi
	done < <(git ls-remote --tags origin)
	return 0
)
bb_exportfn bb_git_moved_tags

## @fn bb_git_update
## Update an already cloned Git repository, when the revision it sits on can
## move: a branch which got new commits.
##
## The update is a fast forward, so nothing already committed is ever lost. A
## revision which is a tag or a changeset designates a fixed commit and is left
## untouched, and so is a branch which received no new commit, one holding local
## commits which are not upstream, and a repository holding uncommitted work.
## @param Directory holding the repository
## @param Branch, tag or changeset the sources sit on
## @print What has been done, or why nothing was
## @return 0 when updated, 2 when there is nothing to update, 3 when the
## repository holds local work and is kept as it is, else error
function bb_git_update () (
	local dir="${1}"
	local revision="${2}"
	cd "${dir}"
	[ $? -ne 0 ] && return 1
	# The branch as it is known here, before the fetch moves it: what it
	# becomes tells a branch which grew from one which was rewritten
	local known=$(git rev-parse --verify --quiet "refs/remotes/origin/${revision}")
	git fetch --quiet --tags origin
	if [ $? -ne 0 ]; then
		# Git refuses to overwrite a tag it already has, so a tag which
		# moved upstream makes the fetch fail. The history of the remote
		# repository changed: what it means for the sources here takes a
		# look by hand, so the update stops and says which tags moved
		local moved=$(bb_git_moved_tags . | tr '\n' ' ')
		if [ -n "${moved}" ]; then
			echo "the history of the remote repository changed, these tags do not designate the same commit any more: ${moved}"
			echo "check by hand what happened upstream before updating"
		else
			echo "unable to fetch from origin"
		fi
		return 1
	fi
	# Only a branch moves: a tag and a changeset designate a fixed commit
	if ! git rev-parse --verify --quiet "refs/remotes/origin/${revision}" > /dev/null; then
		echo "revision '${revision}' is not a branch, nothing to update"
		return 2
	fi
	local upstream=$(git rev-parse "refs/remotes/origin/${revision}")
	# A branch rewritten upstream is not local work: the history of the
	# remote repository changed, and what it means for the sources here
	# takes a look by hand
	if [ -n "${known}" ] && ! git merge-base --is-ancestor "${known}" "${upstream}"; then
		echo "the history of the remote repository changed, branch '${revision}' does not hold commit ${known} any more"
		echo "check by hand what happened upstream before updating"
		return 1
	fi
	# Uncommitted work stops the update, it must not be discarded
	if ! git diff --quiet HEAD; then
		echo "holds uncommitted changes, kept as it is"
		return 3
	fi
	local current=$(git rev-parse HEAD)
	if [ "${current}" = "${upstream}" ]; then
		echo "already on the last commit of '${revision}'"
		return 2
	fi
	# A branch which diverged locally is kept: an update discards nothing
	if ! git merge-base --is-ancestor "${current}" "${upstream}"; then
		echo "holds commits which are not in '${revision}', kept as it is"
		return 3
	fi
	git merge --ff-only "refs/remotes/origin/${revision}"
	[ $? -ne 0 ] && return 1
	# The new commits may move the submodules pointers
	git submodule update --init
	[ $? -ne 0 ] && return 1
	echo "updated from ${current} to ${upstream}"
	return 0
)
bb_exportfn bb_git_update

## @fn bb_git_has_local_work
## Tell if a repository holds work another clone of the same repository does not
## have: uncommitted changes, untracked files, or commits the other clone has
## never seen.
##
## This answers the question asked before a clone is discarded, so anything
## which can not be checked is reported as local work: the answer is never
## optimistic.
## @param Directory holding the repository
## @param Directory holding the repository to compare with
## @print What the repository holds, when it holds local work
## @return 1 when the repository holds local work, 2 when it can not be told,
## 0 when it holds nothing the other clone has not
function bb_git_has_local_work () (
	local dir="${1}"
	local reference="${2}"
	cd "${dir}"
	[ $? -ne 0 ] && return 2
	if [ ! -d .git ]; then
		echo "${dir} is not a Git repository"
		return 2
	fi
	if ! git diff --quiet HEAD; then
		echo "holds uncommitted changes"
		return 1
	fi
	if [ -n "$(git ls-files --others --exclude-standard)" ]; then
		echo "holds untracked files"
		return 1
	fi
	local head=$(git rev-parse HEAD)
	[ $? -ne 0 ] && return 2
	if ! git -C "${reference}" cat-file -e "${head}^{commit}" 2> /dev/null; then
		echo "sits on commit ${head}, which ${reference} does not have"
		return 1
	fi
	return 0
)
bb_exportfn bb_git_has_local_work
