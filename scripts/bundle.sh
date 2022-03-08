#!/usr/bin/env sh
SRC="${1}"
DEST="${2}"
HASH="${3}"
cp -r "${SRC}" "${DEST}" >/dev/null 2>&1
echo "{\"hash\":\"${HASH}\"}"
