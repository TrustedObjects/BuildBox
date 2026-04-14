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
