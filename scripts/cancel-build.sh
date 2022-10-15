#!/bin/bash

BUILD="$1"

jobs_in_build=$(openqa-cli api jobs build="$BUILD" | jq -r '.jobs[].id' | xargs)

for id in $jobs_in_build
do
    openqa-cli api -X POST "jobs/$id/cancel"
done
