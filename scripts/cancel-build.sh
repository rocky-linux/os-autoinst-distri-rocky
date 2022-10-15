#!/bin/bash

BUILD="$1"

## Usage: Cancels all outstanding openQA jobs for the specified build
# scripts/cancel-build.sh 20221014.133700-My-Named-Build

jobs_in_build=$(openqa-cli api jobs build="$BUILD" | jq -r '.jobs[].id' | xargs)

for id in $jobs_in_build
do
    openqa-cli api -X POST "jobs/$id/cancel"
done
