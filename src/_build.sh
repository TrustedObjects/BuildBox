## @brief Build packages
## Generic build functions, relying on build modes implemented in
## `_bb_build_{mode}.sh` files, where `{mode}` stands for the build mode
## (autotools, make, ...).

## @fn _bb_build_package
## This function should not be called directly, it is used by
## bb_build_package() and bb_build_package_fast().
## @param Mode, 1 = fast, else normal (refer to package build mode to know what
## differs between these modes).
## Package has to be already built in normal mode.
## @param Package name
## @param Build options (allowed to contain shell variables), these options are
## appended after package provided options.
## @env `BB_PROJECT_DIR`: current project path
## @env `BB_TARGET_SRC_DIR`: path where cloned package are stored
## @return 0 on success
function _bb_build_package () (
	local fast=${1}
	shift
	local pkg_name=${1}
	shift
	local pkg_opts=${@}
	bb_clone_package ${pkg_name}
	[ $? -ne 0 ] && return 1
	bb_load_package ${pkg_name}
	[ $? -ne 0 ] && return 1
	if [ -z "${SRC_BUILD}" ]; then
		echo "No build required."
		return 0
	fi
	pkg_opts=$(eval echo "${SRC_CONFIG} ${pkg_opts}")
	local pkg_dir=$(bb_escape_package_name ${pkg_name})
	bb_source _build_${SRC_BUILD}.sh
	[ $? -ne 0 ] && return 1
	if [ ${fast} -ne 1 ]; then
		local build_cmd="bb_${SRC_BUILD}_build"
	else
		local build_cmd="bb_${SRC_BUILD}_build_fast"
	fi
	if ! typeset -f ${build_cmd} > /dev/null; then
		echo "Unsupported build mode: ${build_cmd}"
		return 1
	fi
	${build_cmd} "${BB_TARGET_SRC_DIR}/${pkg_dir}" ${pkg_opts} < /dev/null
	return $?
)

## @fn bb_build_package
## Generic function to build a package.
## Sources are built and installed in the target `build` directory.
##
## Package is cloned if not already done.
##
## Package does not need to be referenced in target packages file.
##
## If package `SRC_BUILD` is not defined, return with success. If `SRC_BUILD`
## mode is not supported, return with error.
## @param package name
## @param build options
## @env `BB_PROJECT_DIR`: current project path
## @env `BB_TARGET_SRC_DIR`: path where cloned package are stored
## @return 0 on success
function bb_build_package {
	_bb_build_package 0 $@
	return $?
}
bb_exportfn bb_build_package

## @fn bb_build_package_fast
## Generic function to build package (fast mode).
## Package has to be already built in normal mode.
## @param Package name
## @param Build options
## @env `BB_PROJECT_DIR`: current target path
## @env `BB_TARGET_SRC_DIR`: path where cloned package are stored
## @return 0 on success
function bb_build_package_fast {
	_bb_build_package 1 $@
	return $?
}
bb_exportfn bb_build_package_fast

## @fn bb_clean_package
## Generic function to clean package built files.
## Installed files in target `build` directory are not affected.
## No error is returned if the package is not already built or not cloned.
## @param Package name
## @env `BB_PROJECT_DIR`: current target path
## @env `BB_TARGET_SRC_DIR`: path where cloned package are stored
## @return 1 if package doesn't exists, or if build mode clean operation is not
## supported, 0 on success
function bb_clean_package () (
	local pkg_name=${1}
	bb_load_package ${pkg_name}
	[ $? -ne 0 ] && return 1
	if [ -z "${SRC_BUILD}" ]; then
		echo "No clean required."
		return 0
	fi
	local pkg_dir=$(bb_escape_package_name ${pkg_name})
	bb_source _build_${SRC_BUILD}.sh
	local clean_cmd="bb_${SRC_BUILD}_clean"
	if ! typeset -f ${clean_cmd} > /dev/null; then
		echo "Unsupported clean operation for this build mode: ${clean_cmd}"
		return 1
	fi
	${clean_cmd} "${BB_TARGET_SRC_DIR}/${pkg_dir}" < /dev/null
	return $?
)
bb_exportfn bb_clean_package

## @fn bb_wipe_package
## Generic function to wipe package sources and built files from target and
## project.
## Installed files in target `build` directory are not affected.
## No error is returned if the package is not already built or not cloned.
## @param Package name
## @env `BB_TARGET_SRC_DIR`: path where cloned package are stored
## @return 0 on suuccess
function bb_wipe_package () (
	local pkg_name=${1}
	local pkg_dir=$(bb_escape_package_name ${pkg_name})
	# remove built files
	bb_clean_package ${pkg_name}
	[ $? -ne 0 ] && return 1
	# remove sources
	if [ -d ${BB_PROJECT_SRC_DIR}/${pkg_dir} ]; then
		bb_trash ${BB_PROJECT_SRC_DIR}/${pkg_dir} > /dev/null
	fi
	pkg_dir_no_revision=$(bb_get_package_name_no_revision ${pkg_dir})
	easy_link=${BB_TARGET_SRC_DIR}/${pkg_dir_no_revision}.sources
	if [ -L ${easy_link} ]; then
		rm ${easy_link}
	fi
	if [ -L ${BB_TARGET_SRC_DIR}/${pkg_dir} ]; then
		rm ${BB_TARGET_SRC_DIR}/${pkg_dir}
	elif [ -d ${BB_TARGET_SRC_DIR}/${pkg_dir} ]; then
		bb_trash ${BB_TARGET_SRC_DIR}/${pkg_dir} > /dev/null
	else
		return 0
	fi
	return $?
)
bb_exportfn bb_wipe_package

## @fn bb_get_build_log_warning_count
## Generic function to get build log file warning count.
## Supported warning format in build log:
## - `warning:` (GCC)
## - `[Warning]` (Mbed)
## @param Log file path (file must exists, else an error is returned)
## @print Warning count
## @return 0 on success
function bb_get_build_log_warning_count {
	if [ ! -f ${1} ]; then
		return 1
	fi
	grep -E "[Ww]{1}arning[]:]{1}" ${1} | wc -l
	return 0
}
bb_exportfn bb_get_build_log_warning_count

## @fn bb_stat_package
## Generic function to stat package. Refer to build mode implementation for
## available stats. Commonly available:
## - `warning`: to get the build warnings count.
##
## @param Package name
## @param Type of stat
## @env `BB_PROJECT_DIR`: current target path
## @env `BB_TARGET_SRC_DIR`: path where cloned package are stored
## @print Result, depending on requested information.
## @return 0 on success, else build mode stat is not supported or returned an error.
function bb_stat_package () {
	local pkg_name=${1}
	local stat=${2}
	bb_load_package ${pkg_name}
	[ $? -ne 0 ] && return 1
	if [ -z "${SRC_BUILD}" ]; then
		return 0
	fi
	local pkg_dir=$(bb_escape_package_name ${pkg_name})
	bb_source _build_${SRC_BUILD}.sh
	local stat_cmd="bb_${SRC_BUILD}_stat_${2}"
	if ! typeset -f ${stat_cmd} > /dev/null; then
		echo "Unsupported build mode to stat sources: ${stat_cmd}"
		return 1
	fi
	${stat_cmd} "${BB_TARGET_SRC_DIR}/${pkg_dir}" < /dev/null
	return $?
}
bb_exportfn bb_stat_package

## @fn bb_package_supports_sources_sharing
## Generic function to know if a package supports sources sharing.
## Package doesn't need to be cloned yet. Returns 0 if package build mode is
## unknown.
## @param Package name
## @return 1 if package supports sources sharing, 0 if not
function bb_package_supports_sources_sharing () {
	local pkg_name=${1}
	bb_load_package ${pkg_name}
	[ $? -ne 0 ] && return 0
	if [ -z "${SRC_BUILD}" ]; then
		return 0
	fi
	bb_source _build_${SRC_BUILD}.sh
	if [ -n "${SRC_SUPPORTS_SHARING}" ]; then
		# Sources sharing support is declared in package file, use this
		if [ ${SRC_SUPPORTS_SHARING} -eq 0 ]; then
			ret=0
		else
			ret=1
		fi
	else
		# Sources sharing support depends on build mode
		bb_function_exists bb_${SRC_BUILD}_supports_sources_sharing
		local ret=$?
		if [ $ret -eq 1 ]; then
			bb_${SRC_BUILD}_supports_sources_sharing
			ret=$?
		fi
	fi
	return $ret
}
bb_exportfn bb_package_supports_sources_sharing

## @fn bb_get_package_build_dir
## Get package build directory absolute path.
## If package build mode does not implement a `bb_${mode}_get_build_dir`
## function, package sources dir is returned.
## @param Package name
## @print Package build directory absolute path
## @return 0 on success
function bb_get_package_build_dir () {
	pkg_name=${1}
	local pkg_dir=$(bb_escape_package_name ${pkg_name})
	bb_load_package ${pkg_name}
	[ $? -ne 0 ] && return 1
	if [ -z "${SRC_BUILD}" ]; then
		return 1
	fi
	bb_source _build_${SRC_BUILD}.sh
	bb_function_exists bb_${SRC_BUILD}_get_build_dir
	if [ $? -ne 1 ]; then
		bb_get_package_src_dir ${pkg_name}
		return $?
	fi
	pkg_build_dir=$(bb_${SRC_BUILD}_get_build_dir "${BB_TARGET_SRC_DIR}/${pkg_dir}")
	if [ $? -ne 0 ]; then
		return 1
	fi
	if [ ! -d ${pkg_build_dir} ]; then
		return 1
	fi
	echo ${pkg_build_dir}
	return 0
}
bb_exportfn bb_get_package_build_dir
