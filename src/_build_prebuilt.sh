## @brief Pre-built packages
## Fake build mode used to install pre-built package

## @fn bb_prebuilt_build
## Install pre-built package.
## @param Package directory
## @return 0 on success
function bb_prebuilt_build () (
	bb_trap_errors_silent
	local pkg_dir=${1}
	if [ $# -ne 1 ]; then
		echo "Prebuilt package doesn't support options"
		return 1
	fi
	mkdir -p ${PREFIX}
	cp -af ${pkg_dir}/* ${PREFIX}
	return $?
)
bb_exportfn bb_prebuilt_build

## @fn bb_prebuilt_build_fast
## Same as bb_prebuilt_build()
## @param Package directory
## @return 0 on success
function bb_prebuilt_build_fast () (
	bb_prebuilt_build ${1}
	return $?
)
bb_exportfn bb_prebuilt_build_fast

## @fn bb_prebuilt_clean
## Nothing to clean for prebuilt.
## @param Package directory
function bb_prebuilt_clean () (
	local pkg_dir=${1}
)
bb_exportfn bb_prebuilt_clean

## @fn bb_prebuilt_stat_warning
## No warnings for prebuilt.
## @param package directory
## @print Always "0"
function bb_prebuilt_stat_warning {
	local pkg_dir=${1}
	echo "0"
}
bb_exportfn bb_prebuilt_stat_warning

## @fn bb_prebuilt_supports_sources_sharing
## Prebuilt build plugin supports sources sharing
## @return 1
function bb_prebuilt_supports_sources_sharing {
	return 1
}
bb_exportfn bb_prebuilt_supports_sources_sharing
