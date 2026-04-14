#!/bin/bash
set -e

API_DIR=$(cd -- "${1}" &> /dev/null && pwd)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

cp ${SCRIPT_DIR}/api.md.template ${SCRIPT_DIR}/api.md
for source in $(find ${API_DIR} -name '*.sh'|sort -V); do
	echo -n "Processing $(basename ${source})... "
	${SCRIPT_DIR}/sh2md.sh ${source} ${SCRIPT_DIR}/api.md
	echo -e "\e[32mOK\e[0m"
done
