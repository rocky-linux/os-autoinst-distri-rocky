#!/bin/bash
set -e

BUILD_NAME=$1

printf 'Test | Result\n=============\n'
openqa-cli api -X GET jobs build="$BUILD_NAME" | \
    jq -r '.jobs[] | {name,result} | join(" | ") | split("-") | last' | \
    sort
