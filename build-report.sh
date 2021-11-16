#!/bin/bash
set -e

BUILD_NAME=$1

printf '# Build%s\n' "$BUILD_NAME"
printf "| Test | Result | Failure Reason | Effort to Fix | Notes |\n"
printf "| ---- | ------ | -------------- | ------------ | ----- |\n"

openqa-cli api -X GET jobs build="$BUILD_NAME" | \
    jq -r '.jobs[] | {name,result} | join(" | ") | split("-") | last' | \
    sort | \
    sed 's,^,| ,g;s,$, | | | |,g'
