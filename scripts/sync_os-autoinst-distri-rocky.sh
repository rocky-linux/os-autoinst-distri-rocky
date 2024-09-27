#!/bin/bash

LOG=/tmp/sync_os-autoinst-distri-rocky.sh.log
date -Isec > "${LOG}"

(cd /var/lib/openqa/tests/rocky && git checkout main && git fetch -p && git pull) >> "${LOG}" 2>&1
(cd /var/lib/openqa/tests/rocky && ./fifloader.py -u -l templates.fif.json templates-updates.fif.json) >> "${LOG}" 2>&1
