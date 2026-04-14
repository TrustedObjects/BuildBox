#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Usage: $0 <input_file.sh> <output_file.md>"
	exit 1
fi
INPUT=${1}
OUTPUT=${2}

function error {
	>&2 echo -e "\e[31mError\e[0m: ${1}"
	exit 1
}

FILE_HEAD=""

# Section iterator
# Possible values for section_* variables:
# - 0: section not seen already
# - 1: current section
# - >1: already processed section
declare -i section_param=0
declare -i section_env=0
declare -i section_setenv=0
declare -i section_resetenv=0
declare -i section_print=0
declare -i section_return=0
last_section=
current_function=
function enter_section {
	local section=${1}
	local section_state=section_${section}
	if [[ "${section}" == "fn" ]]; then
		section_param=0
		section_env=0
		section_setenv=0
		section_resetenv=0
		section_print=0
		section_return=0
		last_section="${section}"
		if [ -z "${current_function}" ]; then
			echo -e "\n**Source file:** \`$(basename ${INPUT})\`" >> ${OUTPUT}
		fi
		current_function=${line}
		return 0
	fi

	if [ -z "${last_section}" ]; then
		error "${section} out of any function"
	fi
	if [[ "${section}" != "${last_section}" ]]; then
		if [[ -n "${last_section}" ]]; then
			if [[ "${last_section}" != "print" ]] && [[ "${last_section}" != "return" ]]; then
				local last_section_state=section_${last_section}
				eval ${last_section_state}=2
			fi
		fi
		if [ ${!section_state} == 2 ]; then
			error "non-contiguous @${section} for ${current_function}()"
		elif [ ${!section_state} == 3 ]; then
			error "only one occurence of @${section} is accepted for ${current_function}()"
		fi
	fi

	if [[ "${section}" == "print" ]] || [[ "${section}" == "return" ]]; then
		eval ${section_state}=3
	else
		eval ${section_state}=1
	fi
	last_section=${section}
	return 0
}
function reset_section {
	section_param=0
	section_env=0
	section_setenv=0
	section_resetenv=0
	section_print=0
	section_return=0
	last_section=
}

# Replaces "function_name()" occurences by a link to function_name
function link_fn {
	line="${1}"
	# create the link
	line=$(echo "${line}" | sed 's/\([a-zA-Z][a-zA-Z0-9_]*\)()/[\1()](#\1)/g')
	# recursively replace '_' by '-' in created links
	echo "${line}" | sed -e ':loop' -e 's/\(\[[a-zA-Z][a-zA-Z0-9_]*()\](#[a-zA-Z0-9\-]*\)_\([a-zA-Z0-9_]*)\)/\1-\2/g' -e 't loop'
}

declare -i parsed_count=0
while read -r line; do
	if [[ "${line}" != "##"* ]]; then
		reset_section
		continue
	fi
	line=$(echo ${line} | sed 's/^##\s*//')
	line=$(echo ${line} | sed 's/</\\</g')
	line=$(echo ${line} | sed 's/>/\\>/g')
	line=$(link_fn "${line}")
	if [ $parsed_count -eq 0 ] && [[ "${line}" != "@brief"* ]]; then
		error "@brief tag must appear first in $(basename ${INPUT})"
	fi
	case ${line} in
		"@brief"*)
			line=$(echo ${line} | sed 's/^@brief\s*//')
			if [ -z "${current_function}" ]; then
				echo "## ${line}" >> ${OUTPUT}
			else
				echo -e "${line}\n" >> ${OUTPUT}
			fi
			;;
		"@fn"*)
			enter_section "fn" ${line}
			line=$(echo ${line} | sed 's/^@fn\s*//') # remove prefix
			line=$(echo ${line} | sed 's/_/\\_/g') # escape underscores
			echo "### ${line}()" >> ${OUTPUT}
			;;
		"@param"*)
			if [ $section_param -eq 0 ]; then
				enter_section "param"
				echo "#### Parameters" >> ${OUTPUT}
				section_param=1
			fi
			line=$(echo ${line} | sed 's/^@param\s*//')
			echo "- ${line}" >> ${OUTPUT}
			;;
		"@env"*)
			if [ $section_env -eq 0 ]; then
				enter_section "env"
				echo "#### Expected environment" >> ${OUTPUT}
				section_env=1
			fi
			line=$(echo ${line} | sed 's/^@env\s*//')
			echo "- ${line}" >> ${OUTPUT}
			;;
		"@setenv"*)
			if [ $section_setenv -eq 0 ]; then
				enter_section "setenv"
				echo "#### Set environment" >> ${OUTPUT}
				section_setenv=1
			fi
			line=$(echo ${line} | sed 's/^@setenv\s*//')
			echo "- ${line}" >> ${OUTPUT}
			;;
		"@resetenv"*)
			if [ $section_resetenv -eq 0 ]; then
				enter_section "resetenv"
				echo "#### Reset environment" >> ${OUTPUT}
				section_resetenv=1
			fi
			line=$(echo ${line} | sed 's/^@resetenv\s*//')
			echo "- ${line}" >> ${OUTPUT}
			;;
		"@print"*)
			enter_section "print"
			line=$(echo ${line} | sed 's/^@print\s*//')
			echo "#### Print" >> ${OUTPUT}
			echo "${line}" >> ${OUTPUT}
			;;
		"@return"*)
			enter_section "return"
			line=$(echo ${line} | sed 's/^@return\s*//')
			echo "#### Return" >> ${OUTPUT}
			echo "${line}" >> ${OUTPUT}
			;;
		*)
			echo ${line} >> ${OUTPUT}
			;;
	esac
	parsed_count=$parsed_count+1
done < ${INPUT}
