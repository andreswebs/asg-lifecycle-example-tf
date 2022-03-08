#!/usr/bin/env sh
DIR="${1}"
HASH="${2}"
cd "${DIR}" || exit 1
npm install >/dev/null 2>&1
echo "{\"hash\":\"${HASH}\"}"
