## @brief Targets

## @fn bb_get_target_profile_path
## Get target profile absolute path
## @param Target name
## @print Target absolute path, or nothing if not found
## @return 0 if the target is found
function bb_get_target_profile_path {
	local target=$1
	if [ -f ${BB_PROJECT_PROFILE_DIR}/target.${target} ]; then
		echo ${BB_PROJECT_PROFILE_DIR}/target.${target}
	else
		return 1
	fi
	return 0
}
bb_exportfn bb_get_target_profile_path

## @fn bb_project_target_name_from_file
## Get project target name from target file path.
## @param Target file path
## @print Target name
function bb_project_target_name_from_file {
	local file=$1
	local profile=$(basename ${file})
	profile=${profile#target.}
	echo ${profile}
}
bb_exportfn bb_project_target_name_from_file

## @fn bb_get_project_current_target
## Get current project target from .bbx/.state.
## @print Target name (empty string if no current target is defined)
function bb_get_project_current_target {
	local state_file="${BB_PROJECT_PROFILE_DIR}/.state"
	if [ ! -f "${state_file}" ]; then
		echo ""
	else
		cat "${state_file}"
	fi
}
bb_exportfn bb_get_project_current_target

## @fn bb_reset_project_current_target
## Reset current target to let it undefined.
## @resetenv `BB_TARGET`: target name
## @resetenv `BB_TARGET_DIR`: target absolute path
## @resetenv `BB_TARGET_SRC_DIR`: target packages sources absolute path
## @resetenv `BB_TARGET_BUILD_DIR`: target built (installed) files absolute path
function bb_reset_project_current_target {
	unset BB_TARGET
	unset BB_TARGET_DIR
	unset BB_TARGET_SRC_DIR
	unset BB_TARGET_BUILD_DIR
}
bb_exportfn bb_reset_project_current_target

## @fn bb_set_project_current_target
## Set current project target. Persists selection in .bbx/.state.
## @param Target name
## @env `BB_TARGET`: target name
## @env `BB_TARGET_DIR`: target absolute path
## @env `BB_TARGET_SRC_DIR`: target packages sources absolute path, containing
## target packages sources, which are symlinked or copied from
## `BB_PROJECT_SRC_DIR` (depends on build mode)
## @env `BB_TARGET_BUILD_DIR`: target built (installed) files absolute path
## @return 0 on success
function bb_set_project_current_target {
	local target=${1}
	if [ ! -f ${BB_PROJECT_PROFILE_DIR}/target.${target} ]; then
		>&2 echo "Unknown target ${target} !"
		return 1
	fi
	export BB_TARGET=${target}
	export BB_TARGET_DIR=${BB_PROJECT_DIR}/${BB_TARGET}
	export BB_TARGET_SRC_DIR=${BB_TARGET_DIR}/src
	export BB_TARGET_BUILD_DIR=${BB_TARGET_DIR}/build
	# Persist current target selection
	echo ${target} > "${BB_PROJECT_PROFILE_DIR}/.state"
	[ $? -ne 0 ] && return 1
	bb_set_local_env # for scripts calling bb_set_project_current_target
	return $?
}
bb_exportfn bb_set_project_current_target

## @fn bb_set_project_default_target
## Set current project target to the project default one.
## @env Like bb_set_project_current_target()
## @return 0 on success
function bb_set_project_default_target {
	if [ -L ${BB_PROJECT_PROFILE_DIR}/default_target ]; then
		local target=$(bb_project_target_name_from_file $(readlink ${BB_PROJECT_PROFILE_DIR}/default_target))
	else
		local target_file=$(find ${BB_PROJECT_PROFILE_DIR} -maxdepth 1 -iname 'target.*' | head -n 1)
		if [ -z "${target_file}" ]; then
			bb_reset_project_current_target
			return 0
		fi
		local target=$(bb_project_target_name_from_file ${target_file})
		echo -e "No default target, using \e[1m${target}\e[0m."
		echo -e "Consider defining a default target by committing a \e[1mdefault_target\e[0m symlink to your project pointing to one of its targets."
	fi
	bb_set_project_current_target ${target}
	return $?
}
bb_exportfn bb_set_project_default_target

## @fn bb_get_project_targets
## Get project targets names list.
## @print Project targets list (one per line).
## @return 0 on success
function bb_get_project_targets {
	if [ -z "${BB_PROJECT_PROFILE_DIR}" ] || [ ! -d "${BB_PROJECT_PROFILE_DIR}" ]; then
		return 1
	fi
	while read -r target; do
		if [ -f "${BB_PROJECT_PROFILE_DIR}/${target}" ]; then
			echo "${target#target.}"
		fi
	done < <(find "${BB_PROJECT_PROFILE_DIR}" -maxdepth 1 -type f -name 'target.*' -exec basename {} \;)
	return 0
}
bb_exportfn bb_get_project_targets

## @fn bb_get_project_targets_formatted
## Format project targets list.
## @param Output mode: set to 0 for simple list on a single line separated by
## spaces, else detailed view
## @print Formatted targets list.
## @return 0 on success
function bb_get_project_targets_formatted {
	if [ $# -ne 1 ]; then
		return 1
	fi
	local current_target=$(bb_get_project_current_target)
	local detailed
	if [ ${1} -eq 0 ]; then
		detailed=0
		separator=" "
	else
		detailed=1
		separator="\n"
	fi
	local targets
	targets=$(bb_get_project_targets)
	[ $? -ne 0 ] && return 1
	local first_occurence=1
	local targets_txt=""
	while read -r target; do
		if [ $first_occurence -ne 1 ]; then
			targets_txt+="${separator}"
		fi
		if [[ "${target}" == "${current_target}" ]]; then
			targets_txt+="\e[34m${target}\e[0m"
		else
			targets_txt+="${target}"
		fi
		if [ $detailed -eq 1 ]; then
			description=$(bb_get_target_description ${target})
			if [ -n "${description}" ]; then
				targets_txt+=" - ${description}"
			fi
			cpu=$(bb_get_target_cpu ${target})
			targets_txt+=" (${cpu})"
		fi
		first_occurence=0
	done < <(echo "${targets}")
	echo -e ${targets_txt}
	return 0
}
bb_exportfn bb_get_project_targets_formatted

## @fn bb_get_target_cpu
## Get target CPU
## @param Target name
## @print Target CPU
## @return 0 if target is found
function bb_get_target_cpu () (
	target=$1
	target_profile=$(bb_get_target_profile_path ${target})
	if [ $? -ne 0 ]; then
		return 1
	fi
	bb_source ${target_profile}
	echo ${CPU}
	return 0
)
bb_exportfn bb_get_target_cpu

## @fn bb_get_target_description
## Get specified current project target description
## @param Target name
## @print Description
## @return 0 if target is found
function bb_get_target_description () (
	target=$1
	target_profile=$(bb_get_target_profile_path ${target})
	if [ $? -ne 0 ]; then
		return 1
	fi
	bb_source ${target_profile}
	echo ${DESCRIPTION}
	return 0
)
bb_exportfn bb_get_target_description

## @fn bb_get_target_vars
## Get target variables
## @param Target name
## @print Target variables list, formatted like this for example:
## - VAR_1="val1"
## - VAR_2=10
## @return 0 on success
function bb_get_target_vars {
	target=$1
	target_profile=$(bb_get_target_profile_path ${target})
	if [ $? -ne 0 ]; then
		return 1
	fi
	cat ${target_profile} | grep "^VAR_.*="
	return 0
}
bb_exportfn bb_get_target_vars

## @fn bb_save_last_target
## Save the current target name so it can be restored later by
## bb_restore_last_target. Call this before any operation that may switch the
## current target (e.g. before running a dist or test script).
## @setenv BB_LAST_TARGET  saved target name
function bb_save_last_target {
	export BB_LAST_TARGET="${BB_TARGET}"
}
bb_exportfn bb_save_last_target

## @fn bb_restore_last_target
## Restore the target previously saved by bb_save_last_target.
## If the current target has changed, switches back and persists to .state.
## Does nothing if bb_save_last_target was not called.
## @resetenv BB_LAST_TARGET
## @return 0 on success
function bb_restore_last_target {
	if [ -z "${BB_LAST_TARGET}" ]; then
		return 0
	fi
	if [ "${BB_LAST_TARGET}" != "${BB_TARGET}" ]; then
		bb_set_project_current_target "${BB_LAST_TARGET}"
	fi
	unset BB_LAST_TARGET
	return 0
}
bb_exportfn bb_restore_last_target
