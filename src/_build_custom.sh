## @brief Build packages with custom process
## This build mode is used to build components using custom build scripts
## provided by the component itself.
##
## The following scripts are involved, and must be located at component root:
## - `build.sh`: cleanup, build and install the component into $PREFIX
## - `build_fast.sh` (optional): fast build mode (no cleanup, no configuration),
##   if not present 'build.sh' is used instead.
## - `clean.sh`: clean built files (do not uninstall)
## - `warning_count.sh` (optional) prints number of build warnings
##
## Scripts are run from the component root as current working directory.
## These scripts must return 0 on success, else error.

## @fn bb_custom_build
## Build and install with custom `build.sh` script.
## Installation is done under $PREFIX directory.
## @param Package directory
## @param Build options, passed to `build.sh` script
## @return 0 on success
function bb_custom_build () (
	local pkg_dir=${1}
	shift
	local pkg_opts=${@}
	cd ${pkg_dir}
	set -o pipefail
	if [ ! -f ./build.sh ]; then
		>&2 echo "build.sh not found in ${pkg_dir} !"
		return 1
	fi
	./build.sh ${pkg_opts} |& tee build.log
	return $?
)
bb_exportfn bb_custom_build

## @fn bb_custom_build_fast
## Build and install with custom `build_fast.sh` script.
## Fast mode only build sources, with no preceding cleanup or configuration,
## then it is assumed configuration is already done.
## If `build_fast.sh` is not present, `build.sh` is used instead.
## Installation is done under `$PREFIX` directory.
## @param Package directory
## @param Build options, passed to 'build_fast.sh'
## @return 0 on success
function bb_custom_build_fast () (
	local pkg_dir=${1}
	shift
	local pkg_opts=${@}
	cd ${pkg_dir}
	[ $? -ne 0 ] && return 1
	set -o pipefail
	if [ -f build_fast.sh ]; then
		./build_fast.sh ${pkg_opts} |& tee build.log
	else
		if [ ! -f ./build.sh ]; then
			>&2 echo "build.sh not found in ${pkg_dir} !"
			return 1
		fi
		./build.sh ${pkg_opts} |& tee build.log
	fi
	return $?
)
bb_exportfn bb_custom_build_fast

## @fn bb_custom_clean
## Clean build by calling custom `clean.sh` script.
## Built files are cleaned by this custom script, but nothing is uninstalled
## from `$PREFIX` directory.
## @param package directory
## @return 0 on success
function bb_custom_clean () (
	local pkg_dir=${1}
	if [ -d ${pkg_dir} ]; then
		cd ${pkg_dir}
		[ $? -ne 0 ] && return 1
		set -o pipefail
		if [ ! -f ./clean.sh ]; then
			>&2 echo "clean.sh not found in ${pkg_dir} !"
			return 1
		fi
		./clean.sh |& tee clean.log
		return $?
	fi
	return 0
)
bb_exportfn bb_custom_clean

## @fn bb_custom_stat_warning
## Get custom build warnings count with `warning_count.sh` script.
## This script must only print out the number of warnings.
## If this script is not provided, uses bb_get_build_log_warning_count() to get
## warning count from a `build.log` file in package directory.
## And if `build.log` file is not present, nothing is printed.
## @print Warning count
## @param Package directory
function bb_custom_stat_warning {
	local pkg_dir=${1}
	if [ -d ${pkg_dir} ]; then
		cd ${pkg_dir}
		if [ -f warning_count.sh ]; then
			./warning_count.sh
			return
		elif [ -f build.log ]; then
			bb_get_build_log_warning_count "${pkg_dir}/build.log"
			return
		fi
	fi
}
bb_exportfn bb_custom_stat_warning
