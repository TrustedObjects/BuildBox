## @brief BuildBox internal common stuff

BB_API_CALLER=$(basename $(ps -wwo args= $$ | cut -d ' ' -f 2)) > /dev/null 2>&1
if [ $? -ne 0 ]; then
	BB_API_CALLER=buildbox
fi

BUILDBOX_INTERNAL_API="bb_declare_internal_api bb_exportfn"
bb_declare_internal_api() {
	if [[ "${1}" != "bb_"* ]]; then
		>&2 echo "BuildBox API functions must begin with 'bb_', unable to export '${1}()'"
		return 1
	fi
	if ! typeset -f "${1}" > /dev/null 2>&1; then
		>&2 echo "BuildBox API function not found for '${1}'"
		return 1
	fi
	BUILDBOX_INTERNAL_API="${BUILDBOX_INTERNAL_API} ${1}"
}

BB_SETOPT_BACKUP_LIST="errexit\|errtrace\|xtrace"
BB_SETOPT_LIST="+eE"
if [ ! -z ${BB_DEBUG} ]; then
	BB_SETOPT_LIST+=" -xv"
else
	BB_SETOPT_LIST+=" +xv"
fi

## @fn bb_exportfn
## BuildBox API declaration function:
## - Export the function
## - Add a decorator to every API to set BuildBox shell options, and restore them
##
## API functions must begin with 'bb_'. Function must exists when declared.
## @param API name
## @return 0 on success
if [ ! -z "${ZSH_VERSION}" ]; then
	# ZSH case
	bb_exportfn() {
		echo > /dev/null
		if ! bb_declare_internal_api $@; then
			return 1
		fi
		# ZSH doesn't support function export
		functions[$1]='
			cwd="$(pwd)"
			setopt_backup=$(set +o|grep ${BB_SETOPT_BACKUP_LIST})
			eval set ${BB_SETOPT_LIST}
			() { '$functions[$1]'; } "$@"
			local ret=$?
			eval "${setopt_backup}"
			if [ -d "${cwd}" ]; then
				cd "${cwd}"
			fi
			return $ret
		'
	}
else
	# Bash case
	bb_exportfn() {
		if ! bb_declare_internal_api $@; then
			return 1
		fi
		export $@
		bb_declare_internal_api $@
		# Below, there is a workaround to handle errexit.
		# As Bash disables it when spawning subprocesses, we can't get
		# its current value in ${setopt_backup} as others options.
		eval "_inner_$(typeset -f "$1"); $1"'() {
			cwd="$(pwd)"
			setopt_backup=$(set +o|grep ${BB_SETOPT_BACKUP_LIST})
			if [[ ${BB_SETOPT_BACKUP_LIST} == *errexit* ]] && [[ $- == *e* ]]; then
				errexit_restore=1
			else
				errexit_restore=0
			fi
			eval set ${BB_SETOPT_LIST}
			_inner_'"$1"' "$@"
			local ret=$?
			eval "${setopt_backup}"
			if [ ${errexit_restore} -eq 1 ]; then
				set -e
			fi
			if [ -d "${cwd}" ]; then
				cd "${cwd}"
			fi
			return "$ret"
		}'
	}
fi

## @fn bb_is_subpath_of
## Check if a path is parent of another path.
## @param Expected parent path
## @param Path to check
## @return 0 if path has the expected parent, else 1
function bb_is_subpath_of {
	local parent=${1}
	local path=${2}
	local is_subpath=0
	if [[ "${path##${parent}}" == "${path}" ]]; then
		return 1
	else
		return 0
	fi
}
bb_exportfn bb_is_subpath_of

## @fn bb_confirm
## Ask user to confirm, the answer is read from standard input.
## `Y` and `y` are accepted as "yes", else assume "no"
## @param Question prompt
## @print The question prompt followed by ` (y/n) `
## @return 1 if the response is "yes", else 0
function bb_confirm () (
	echo -en "${1} (y/n) "
	if [ -n "$ZSH_VERSION" ]; then
		read -u 0 REPLY
	else
		read REPLY
	fi
	if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
		return 0
	fi
	return 1
)
bb_exportfn bb_confirm

## @fn bb_extract
## Extracts an archive in the current directory.
## Supported formats:
## - .tar.bz2
## - .tar.gz
## - .tar.xz
## - .tgz
## - .zip
## - .tar.zst
## @param Archive file path
## Return 0 on success
function bb_extract {
	if [ ! -f ${1} ] ; then
		echo "Unable to bb_extract ${1}: not a file"
		return 1
	fi
	case ${1} in
		*.tar.bz2) tar xjf $1 ;;
		*.tar.gz) tar xzf $1 ;;
		*.tar.xz) tar xJf $1 ;;
		*.tgz) tar xzf $1 ;;
		*.zip) unzip $1 ;;
		*.tar.zst) tar --use-compress-program=unzstd -xf $1 ;;
		*)
			echo "Unable to bb_extract ${1}: unknown archive format"
			return 1
			;;
	esac
}
bb_exportfn bb_extract

## @fn bb_expand_string_vars
## Expand variables included in a string.
## @param String to expand
## @print Expanded string
function bb_expand_string_vars {
	local string="${1}"
	# A double 'eval' is performed:
	# - the first to expand variables
	# - the second to remove quotes from expanded string variables
	eval $(echo eval "echo ${string}")
}
bb_exportfn bb_expand_string_vars

## @fn bb_function_exists
## Check if a function exists.
## @param Function name
## @return 1 if function exists, else 0
function bb_function_exists {
	local func_name=${1}
	if typeset -f ${func_name} > /dev/null; then
		return 1
	fi
	return 0
}
bb_exportfn bb_function_exists

# List of files sourced with bb_source
if [ -z ${BB_SOURCE_LIST} ]; then
	BB_SOURCE_LIST=()
fi

## @fn bb_source
## Source a file if not already done.
## Unlike `source`, variables exported by the sourced script are not present in
## the caller scope.
## @param File to source
## @return 0 on success
function bb_source {
	local file=${1}
	for item in "${BB_SOURCE_LIST[@]}"; do
		if [[ ${file} == "${item}" ]]; then
			return 0
		fi
	done
	source ${file}
	if [ $? -ne 0 ]; then
		return 1
	fi
	BB_SOURCE_LIST+=("${file}")
	return 0
}
bb_exportfn bb_source

## @fn bb_get_common_parent_path
## Given a list of path, return the common parent path
## @param Path 1
## @param Path 2
## @param ... Path N
##
## At least 2 paths have to be provided, and must be absolute (starting with /).
## @print Common parent path, with no ending /
## @return 0 on success
function bb_get_common_parent_path {
	if [ $# -lt 2 ]; then
		return 1
	fi
	local path1="${1}"
	shift
	local paths="$@"
	if [ -n "$ZSH_VERSION" ]; then
		rd_arr_opt=A
	else
		rd_arr_opt=a
	fi
	local common_parent_path=""
	local try=""

	IFS='/' read -r"$rd_arr_opt" path1_part_array <<< "${path1}"
	IFS=' ' read -r"$rd_arr_opt" path_array <<< "${paths}"
	for part in "${path1_part_array[@]}"; do
		try="${common_parent_path}${part}/"
		for pathN in "${path_array[@]}"; do
			if [[ "${try}" == "/" ]] && [[ ${pathN} != /* ]]; then
				# Path must start with /
				return 1
			fi
			if [[ ${pathN} != ${try}* ]]; then
				# Difference found, return last identified common parent path
				echo ${common_parent_path%/}
				return 0
			fi
		done
		common_parent_path="${try}"
	done

	# Paths are all the same, no difference found
	echo ${common_parent_path%/}
	return 0
}
bb_exportfn bb_get_common_parent_path

## @fn bb_get_relative_path
## Given two paths, return the relative path to go from the first to the second
## @param First path
## @param Second path
## @print Relative path to go to second path from first path
## @return 0 on success
function bb_get_relative_path {
	local path1=${1}
	local path2=${2}
	local parent=$(bb_get_common_parent_path ${path1} ${path2})
	if [ $? -ne 0 ]; then
		return 1
	fi
	# Remove parent prefix
	path1=${path1#${parent}/}
	path2=${path2#${parent}/}
	# Compute relative path to go from path1 to path2
	parent_relative_path=$(echo ${path1} | sed -r 's/[^\/]+/../g')
	echo ${parent_relative_path}/${path2}
	return 0
}
bb_exportfn bb_get_relative_path

## @fn bb_xdg_find_folder
## Find a folder in `XDG_DATA_DIRS`.
##
## `XDG_DATA_DIRS` environment is a paths list separated by colon
## `:` character, pointing to target build directory `share` folder, and to
## tools `share` directories.
## Only the first occurence is returned.
## @param Folder name
## @print The folder absolute path, or nothing if not found
function bb_xdg_find_folder () (
	folder=${1}
	while read -d ':' searchpath; do
		if [ ! -d "${searchpath}" ]; then
			continue
		fi
		folder_path=$(find ${searchpath} -type d -name "${folder}" -print -quit 2>/dev/null)
		if [ -n "${folder_path}" ]; then
			echo ${folder_path}
			return
		fi
	done <<< "$XDG_DATA_DIRS:"
)
bb_exportfn bb_xdg_find_folder

## @fn bb_add_exit_action
## Add an exit action. This function can be called several times, new actions
## are appended after already added ones. These actions are then evaluated on
## script exit.
## @param Action shell code
BB_ON_EXIT=""
function bb_exit_action {
	eval "${BB_ON_EXIT}"
}
if [ ! -z "${ZSH_VERSION}" ]; then
	# ZSH case
	zshexit() {
		bb_exit_action
	}
else
	# Bash case
	trap 'bb_exit_action' EXIT
fi
function bb_add_exit_action {
	local action="${1}"
	BB_ON_EXIT="${BB_ON_EXIT}${action}"$'\n'
}
bb_exportfn bb_add_exit_action
