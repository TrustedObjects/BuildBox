## @brief Trash
## BuildBox Trash is located in the workspace `trash` directory, and can be
## referenced through `BB_TRASH_DIR` environment.
##
## Older files are automatically removed after at least `BB_TRASH_KEEP_DAYS`.
## This remove action is triggered by a call to bb_trash() or to
## bb_trash_dir_content().

## @fn bb_trash_wipe
## Remove everything from trash.
function bb_trash_wipe {
	if [ -d ${BB_TRASH_DIR} ]; then
		chmod -R u+rwX ${BB_TRASH_DIR}
		rm -rf ${BB_TRASH_DIR}/*
	fi
}
bb_exportfn bb_trash_wipe

## @fn bb_trash_clean
## Remove older files from trash (older than `BB_TRASH_KEEP_DAYS`).
function bb_trash_clean {
	if [ -d ${BB_TRASH_DIR} ]; then
		find ${BB_TRASH_DIR} -maxdepth 1 -mtime +${BB_TRASH_KEEP_DAYS} -exec chmod -R u+rwX {} + -exec rm -rf {} +
	fi
}
bb_exportfn bb_trash_clean

## @fn bb_trash
## Trash a file or directory.
## Files sent to trash are renamed with an UUID as suffix to make them unique:
## `filename-UUID`.
##
## The trash older files are automatically cleaned by a call to bb_trash_clean().
## @param File or directory path
## @print File name in the trash
## @return 0 on success, 1 if path is not in workspace.
function bb_trash {
	bb_trash_clean
	local src=$(realpath ${1})
	local trash_uuid="$(basename ${src})-$(uuidgen)"
	if bb_is_subpath_of "${BB_PROJECT_DIR}" "${src}"; then
		local dest="${BB_TRASH_DIR}/${trash_uuid}"
		mkdir -p ${BB_TRASH_DIR}
		touch ${src} # set file last access date to now
		mv ${src} ${dest}
	else
		echo "Unable to trash ${src}: not in workspace"
		return 1
	fi
	echo "${trash_uuid}"
	return 0
}
bb_exportfn bb_trash

## @fn bb_trash_dir_content
## Clean a directory content.
## Files sent to trash are stored in a directory, nammed with the source
## directory name with an UUID suffix to make them unique:
## `directory-UUID`.
##
## The trash older files are automatically cleaned by a call to bb_trash_clean().
## @param Directory path
## @print Directory name where the files have been moved to trash.
## @return 0 on success, 1 if path is not a directory or not in workspace.
function bb_trash_dir_content {
	bb_trash_clean
	local src=$(realpath ${1})
	if [ ! -d ${src} ]; then
		echo "Unable to clear ${src} content: not a directory"
		return 1
	fi
	local trash_uuid="$(basename ${src})-$(uuidgen)"
	if bb_is_subpath_of "${BB_PROJECT_DIR}" "${src}"; then
		local dest="${BB_TRASH_DIR}/${trash_uuid}"
		mkdir -p ${dest}
		find "${src}/." -not -name '.' -prune -print0 | xargs -0 mv --target-directory="${dest}"
	else
		echo "Unable to clear ${src} content: not in workspace"
		return 1
	fi
	echo "${trash_uuid}"
	return 0
}
bb_exportfn bb_trash_dir_content
