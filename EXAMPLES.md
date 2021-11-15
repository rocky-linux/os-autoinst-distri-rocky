## Query all jobs from a named build

    openqa-cli api -X GET jobs build=$BUILDNAME

## Failed jobs in a named build
The overview on the openQA home page counts incompletes as failures

    openqa-cli api -X GET jobs build=$BUILDNAME result=failed,incomplete

## Print a simple report of all tests and their results from a named build

    openqa-cli api -X GET jobs build=$BUILDNAME | jq -r '.jobs[] | {name,result} | join(" ") | split("-") | last' | sort

## Further Reading
[openqa-cli cheat sheet](https://openqa-bites.github.io/openqa/openqa-cli-cheat-sheet/)
[jq cheat sheet](https://lzone.de/cheat-sheet/jq)
