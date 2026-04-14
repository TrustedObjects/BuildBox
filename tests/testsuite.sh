filter=${1}

if [ -z "${BUILDBOX_ENV}" ]; then
	echo "This script must be run from BuildBox environment"
	exit 1
fi

if [ -z "${VERBOSE}" ]; then
	VERBOSE=0
fi

cd ${BB_DIR}/tests
export CWD=$(pwd)
mkdir -p log
mkdir -p run
export FAIL_LINENO_FILE=${CWD}/run/fail_lineno
export FAIL_FILENAME_FILE=${CWD}/run/fail_filename
export FAIL_ASSERT_FILE=${CWD}/run/fail_assert
export SKIP_FILE=${CWD}/run/skip

declare -i succeed_count=0
declare -i failed_count=0
declare -i broken_count=0
declare -i skipped_count=0

export BB_TESTS=""

declare -i declared_tests=0
function bb_declare_test {
	if [[ "${1}" != "test_"* ]]; then
		broken "test function ${1} must be prefixed with 'test_'"
		return 1
	fi
	if (echo "${BB_TESTS}" | grep -Eq ^"${1}"$); then
		broken "duplicate test declaration ${1}"
		return 1
	fi
	if ! typeset -f ${1} > /dev/null; then
		broken "test function not found for ${1}"
		return 1
	fi
	BB_TESTS=$(echo -e "${BB_TESTS}\n${1}")
	declared_tests=$declared_tests+1
}

function is_subpath_of {
	local parent=${1}
	local path=${2}
	[ -z "${parent}" ] && return 1
	[ -z "${path}" ] && return 1
	local is_subpath=0
	if [[ "${path##${parent}}" == "${path}" ]]; then
		return 1
	else
		return 0
	fi
}

# Remove string ANSI format (color, font weight, ...)
# @param Formatted string
# @print Unformatted string
function unformat_string {
	local string="${1}"
	string="$(echo "${string}" | sed -e 's/\x1b\[[0-9;]*m//g')"
	echo "${string}"
}

# Remove useless vertical and horizontal blank spaces.
# Multiple consecutive blank spaces or newlines are replaced by only one.
# Blank spaces at the begining or at the end of lines are removed.
# @param Formatted string
# @print Minimal spaced string
function minspace_string {
	local string="${1}"
	string="$(echo "${string}" | sed -e 's/\s\+/ /g')" # multiple spaces
	string="$(echo "${string}" | sed -e 's/^\s//g')" # start line spaces
	string="$(echo "${string}" | sed -e 's/\s$//g')" # end line spaces
	string="$(echo "${string}" | tr -s '[:space:]')" # multiple new lines
	echo "${string}"
}

## @fn bb_setup_test_project
## Copy a test project fixture into the test workspace.
## @param Fixture name (e.g. "foo_project" or "bar_project")
## @print Absolute path of the prepared project directory
## @return 0 on success
function bb_setup_test_project () (
	local fixture="${1}"
	local fixture_src="${BB_DIR}/tests/repositories/${fixture}"
	if [ ! -d "${fixture_src}/.bbx" ]; then
		>&2 echo "Test fixture not found: ${fixture_src}"
		return 1
	fi
	local dest="${BB_TEST_WORKSPACE}/${fixture}"
	rm -rf "${dest}"
	cp -a "${fixture_src}" "${dest}"
	echo "${dest}"
)

## @fn bb_use_test_project
## Set up a test project fixture and activate it as the current project.
## Replaces the old bb_project_clone + bb_set_current_project pattern.
## @param Fixture name (e.g. "foo_project" or "bar_project")
## @param Target name (optional; selects default target if omitted)
## @setenv BB_PROJECT_DIR and all related env vars
## @return 0 on success
function bb_use_test_project {
	local fixture="${1}"
	local target="${2}"
	local project_dir
	project_dir=$(bb_setup_test_project "${fixture}")
	if [ $? -ne 0 ]; then
		return 1
	fi
	bb_set_current_project "${project_dir}"
	if [ $? -ne 0 ]; then
		return 1
	fi
	if [ -n "${target}" ]; then
		bb_set_project_current_target "${target}"
		return $?
	fi
	return 0
}

function sub_run () (
	# Running in subshell to avoid affecting environment
	source buildbox_utils.sh
	${1}
)

function run {
	local testcase=${1}
	logfile="${CWD}/log/${testcase}.log"
	if [ ${VERBOSE} -lt 2 ]; then
		echo -en "[\e[33mRUN\e[0m]     ${testcase}\r"
		sub_run ${testcase} > "${logfile}" 2>&1
	else
		echo -e "\e[1mRunning ${testcase}...\e[0m"
		log=$(sub_run ${testcase} 2>&1)
		echo -en "\e[34m"
		unformat_string "${log}"
		echo -e "\e[0m"
	fi
	return $?
}

function succeed {
	succeed_count=$succeed_count+1
	echo -e "[\e[32mSUCCEED\e[0m]"
	[ ${VERBOSE} -eq 2 ] && echo
}

function skipped {
	skipped_count=$skipped_count+1
	echo -e "[\e[35mSKIPPED\e[0m]"
	if [ -f "${SKIP_FILE}" ]; then
		comment=$(cat ${SKIP_FILE})
		if [ -n "${comment}" ]; then
			echo "Reason: ${comment}"
		fi
	fi
	[ ${VERBOSE} -eq 2 ] && echo
}

function failed {
	failed_count=$failed_count+1
	echo -e "[\e[31mFAILED\e[0m]"
	if [ -f "${FAIL_LINENO_FILE}" ]; then
		FAIL_LINENO=$(cat ${FAIL_LINENO_FILE})
		FAIL_FILENAME=$(cat ${FAIL_FILENAME_FILE})
		FAIL_ASSERT=$(cat ${FAIL_ASSERT_FILE})
		echo "Assertion '${FAIL_ASSERT}' failed at ${FAIL_FILENAME} line ${FAIL_LINENO}"
	fi
	if [ ${VERBOSE} -eq 1 ]; then
		echo -en "\e[34m"
		log="$(cat ${logfile})"
		unformat_string "${log}"
		echo -e "\e[0m"
	else
		echo "See ${logfile} for more details."
	fi
}

function broken {
	broken_count=$broken_count+1
	echo -e "[\e[41m\e[97mBROKEN\e[0m]" ${1}
}

function cleanup {
	# Reset fail info
	[ -f ${FAIL_LINENO_FILE} ] && rm ${FAIL_LINENO_FILE}
	[ -f ${FAIL_FILENAME_FILE} ] && rm ${FAIL_FILENAME_FILE}
	[ -f ${FAIL_ASSERT_FILE} ] && rm ${FAIL_ASSERT_FILE}
	[ -f ${SKIP_FILE} ] && rm ${SKIP_FILE}
	# Cleanup per-test project copies from the workspace
	if is_subpath_of "${BB_TEST_WORKSPACE}" "${BB_TEST_WORKSPACE}/foo_project" || \
	   is_subpath_of "${BB_TEST_WORKSPACE}" "${BB_TEST_WORKSPACE}/bar_project"; then
		rm -rf "${BB_TEST_WORKSPACE}"/foo_project "${BB_TEST_WORKSPACE}"/bar_project
	fi
	# Temporary directory
	if is_subpath_of "${BB_TEST_WORKSPACE}" "${TMPDIR}"; then
		rm -rf "${TMPDIR}"
		mkdir -p "${TMPDIR}"
	fi
	# Unset project env vars set by previous test
	unset BB_PROJECT_DIR BB_PROJECT_PROFILE_DIR BB_PROJECT_SRC_DIR
	unset BB_CACHE_DIR BB_TOOLS_DIR BB_TRASH_DIR
	unset BB_TARGET BB_TARGET_DIR BB_TARGET_SRC_DIR BB_TARGET_BUILD_DIR
}

function skip {
	echo "${1}" > ${SKIP_FILE}
}

function trace_call {
	if [[ "${SHELL_CMD}" == "/bin/bash" ]]; then
		caller 1 | cut -d ' ' -f 1 > ${FAIL_LINENO_FILE}
		caller 1 | cut -d ' ' -f 3 > ${FAIL_FILENAME_FILE}
	elif [[ "${SHELL_CMD}" == "/bin/zsh" ]]; then
		filetrace="$(echo "${funcfiletrace}[1]" | cut -d ' ' -f 2)"
		echo "${filetrace}" | cut -d ':' -f 2 > ${FAIL_LINENO_FILE}
		echo "${filetrace}" | cut -d ':' -f 1 > ${FAIL_FILENAME_FILE}
	else
		echo "(unknown line)" > ${FAIL_LINENO_FILE}
		echo "(unknown file)" > ${FAIL_FILENAME_FILE}
	fi
}

function assert {
	eval $@
	if [ $? -ne 0 ]; then
		trace_call
		echo "$@" > ${FAIL_ASSERT_FILE}
		exit 1
	fi
}

function asserteq {
	local l="${1}"
	local r="${2}"
	local nbexpr='^[0-9]+$'
	if [[ "${l}" =~ "${nbexpr}" ]] && [[ "${r}" =~ "${nbexpr}" ]]; then
		# numbers
		[ ${l} -eq ${r} ] && return
	else
		[[ "${l}" == "${r}" ]] && return
	fi
	trace_call
	echo "${l} == ${r}" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assertne {
	local l="${1}"
	local r="${2}"
	local nbexpr='^[0-9]+$'
	if [[ "${l}" =~ "${nbexpr}" ]] && [[ "${r}" =~ "${nbexpr}" ]]; then
		# numbers
		[ ${l} -ne ${r} ] && return
	else
		[[ "${l}" != "${r}" ]] && return
	fi
	trace_call
	echo "${l} != ${r}" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assertz {
	local v="${1}"
	[ -z "${v}" ] && return
	trace_call
	echo "${v} empty" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assertn {
	local v="${1}"
	[ -n "${v}" ] && return
	trace_call
	echo "${v} not empty" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assertd {
	local d="${1}"
	[ -d "${d}" ] && return
	trace_call
	echo "${d} is a directory" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assertnd {
	local d="${1}"
	[ ! -d "${d}" ] && return
	trace_call
	echo "${d} is not a directory" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assertf {
	local f="${1}"
	[ -f "${f}" ] && return
	trace_call
	echo "${f} is a file" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assertnf {
	local f="${1}"
	[ ! -f "${f}" ] && return
	trace_call
	echo "${f} is not a file" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assertl {
	local f="${1}"
	[ -L "${f}" ] && return
	trace_call
	echo "${f} is a symlink" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assertnl {
	local f="${1}"
	[ ! -L "${f}" ] && return
	trace_call
	echo "${f} is not a symlink" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assert_exists {
	local f="${1}"
	[ -e "${f}" ] && return
	trace_call
	echo "${f} exists" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assert_does_not_exists {
	local f="${1}"
	[ ! -e "${f}" ] && return
	trace_call
	echo "${f} does not exist" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assert_in_path_list {
	local path_to_find="${1}"
	local list="${2}"
	while read -d ':' entry; do
		if [[ "${path_to_find}" == "${entry}" ]]; then
			return
		fi
	done <<< "$list:"
	trace_call
	echo "${path_to_find} is not in ${list}" > ${FAIL_ASSERT_FILE}
	exit 1
}

function assert_is_subpath_of {
	local parent_path="${1}"
	local child_path="${2}"
	is_subpath_of ${parent_path} ${child_path}
	if [ $? -eq 0 ]; then
		return
	fi
	trace_call
	echo "${child_path} is not in ${parent_path}" > ${FAIL_ASSERT_FILE}
	exit 1
}

# Load tests
while read -r testfile; do
	source ${testfile}
done < <(find cases -type f -name '*.sh')

# Run tests
declare -i test_iterations=0
while IFS= read -r testcase; do
	[ -z "${testcase}" ] && continue
	test_iterations=$test_iterations+1
	[[ "${testcase}" == *"${filter}"* ]] || continue
	if ! cleanup; then
		broken "unable to cleanup test environment"
	fi
	run ${testcase}
	ret=$?
	if [ -f "${SKIP_FILE}" ]; then
		skipped
	elif [ $ret -eq 0 ]; then
		succeed
	else
		failed
	fi
done < <(echo -e "${BB_TESTS}\n")
if [ $test_iterations -ne $declared_tests ]; then
	broken "The last test seems to have consumed stdin ! aborting test suite"
fi

echo
declare -i tested_count=$succeed_count+$failed_count
if [ ${tested_count} -eq 0 ]; then
	echo -e "\e[31mError:\e[0m no test passed !"
	ret=1
elif [ ${failed_count} -eq 0 ] && [ ${broken_count} -eq 0 ]; then
	echo -e "${tested_count} tests passed with \e[32msuccess\e[0m !"
	ret=0
else
	echo -e "${tested_count} tests passed with \e[31merrors\e[0m !"
	echo -e "\tsucceed: \e[32m$succeed_count\e[0m"
	echo -e "\tfailed: \e[31m$failed_count\e[0m"
	if [ ${broken_count} -ne 0 ]; then
		echo -e "\tbroken: \e[41m\e[97m$broken_count\e[0m"
	fi
	ret=1
fi
if [ ${skipped_count} -ne 0 ]; then
	echo -e "\tskipped: \e[35m$skipped_count\e[0m"
fi
exit $ret

