## @brief Sources
## Generic sources management mechanism, relying on `_bb_clone_{tool}.sh` files,
## where `{tool}` stand for the sources scraping tool (Git, HTTP, ...).

## @fn bb_clone_package
## Generic function to clone package sources.
## Packages sources are cloned into `BB_PROJECT_SRC_DIR` directory, and then:
## - symlinked into `BB_TARGET_SRC_DIR` directory if used build plugin supports
##   sources sharing,
## - or copied into `BB_TARGET_SRC_DIR` directory if build plugin does not
##   supports sources sharing.
##
## Package does not need to be referenced in target packages file.
##
## If package is in sub-folder in project packages repository, this sub-folder
## is kept in `BB_PROJECT_SRC_DIR`.
##
## In case of symlink, the link target path is relative.
## `BB_PROJECT_SRC_DIR` and `BB_TARGET_SRC_DIR` are created if they don't exist.
##
## In `BB_TARGET_SRC_DIR`, a link is created to ease access to package sources
## without knowing the revision. The link name is `package_name.sources` (base
## name, no revision in package name). This links point to packages sources in
## `BB_TARGET_SRC_DIR`.
## @param Package name
## @env `BB_PROJECT_PROFILE_DIR`: current project path
## @env `BB_PROJECT_SRC_DIR`: path where cloned package are stored
## @env `BB_TARGET_SRC_DIR`: path where cloned package are symlinked
## @return 0 on success
function bb_clone_package () (
	local pkg_name=${1}
	bb_load_package ${pkg_name}
	[ $? -ne 0 ] && return 1
	local pkg_dir=$(bb_escape_package_name "${pkg_name}")
	bb_source _clone_${SRC_PROTO}.sh
	[ $? -ne 0 ] && return 1
	if ! typeset -f bb_${SRC_PROTO}_clone > /dev/null; then
		echo "Unsupported protocol to clone sources: ${SRC_PROTO}"
		return 1
	fi
	if [[ ! -L ${BB_TARGET_SRC_DIR}/${pkg_dir} ]] && [[ ! -d ${BB_TARGET_SRC_DIR}/${pkg_dir} ]]; then
		if [ ! -d ${BB_PROJECT_SRC_DIR}/${pkg_dir} ]; then
			if [ -d ${BB_PROJECT_SRC_DIR}/.tmp ]; then
				rm -rf ${BB_PROJECT_SRC_DIR}/.tmp
				[ $? -ne 0 ] && return 1
			fi
			# Clone in a temporary folder, to be sure to have the
			# complete clone in case of interruption, which is
			# created from temporary folder after successful clone
			bb_${SRC_PROTO}_clone ${SRC_URI} \
				${BB_PROJECT_SRC_DIR}/.tmp ${SRC_REVISION}
			[ $? -ne 0 ] && return 1
			# Post-clone action, if specified
			if typeset -f SRC_POST_CLONE_HOOK > /dev/null; then
				echo "Running post-clone hook..."
				cd ${BB_PROJECT_SRC_DIR}/.tmp
				SRC_POST_CLONE_HOOK
				[ $? -ne 0 ] && return 1
			fi
			mkdir -p ${BB_PROJECT_SRC_DIR}
			mv ${BB_PROJECT_SRC_DIR}/.tmp \
				${BB_PROJECT_SRC_DIR}/${pkg_dir}
			[ $? -ne 0 ] && return 1
		fi
		mkdir -p ${BB_TARGET_SRC_DIR}
		# If build plugin used by this package supports sources sharing,
		# symlink sources from project to target
		bb_package_supports_sources_sharing ${pkg_name}
		if [ $? -eq 1 ]; then
			# Get relative path to go from target sources dir to project sources dir
			relative_path=$(bb_get_relative_path ${BB_TARGET_SRC_DIR} ${BB_PROJECT_SRC_DIR})
			ln -s ${relative_path}/${pkg_dir} \
				${BB_TARGET_SRC_DIR}/${pkg_dir}
		else
			cp -a ${BB_PROJECT_SRC_DIR}/${pkg_dir} \
				${BB_TARGET_SRC_DIR}/${pkg_dir}
		fi
		[ $? -ne 0 ] && return 1
		# Create link to ease access to package sources without knowing
		# its revision
		local pkg_name_no_revision=$(bb_escape_package_name $(bb_get_package_name_no_revision ${pkg_name}))
		local easy_link=${BB_TARGET_SRC_DIR}/${pkg_name_no_revision}.sources
		if [ -L ${easy_link} ]; then
			rm ${easy_link}
		fi
		ln -s ${pkg_dir} ${easy_link}
	fi
	return 0
)
bb_exportfn bb_clone_package

## @fn bb_is_package_cloned
## Check if a package is cloned.
## @param Target name
## @param Package name
## @return 1 if package is cloned, else 0
function bb_is_package_cloned {
	local target=${1}
	local pkg_name=${2}
	local pkg_dir=$(bb_escape_package_name "${pkg_name}")
	local target_src_dir="${BB_PROJECT_DIR}/${target}/src"
	if [ ! -d ${target_src_dir}/${pkg_dir} ]; then
		return 0
	fi
	return 1
}
bb_exportfn bb_is_package_cloned
