#!/usr/bin/env bash

/usr/sbin/nginx -t && /usr/sbin/nginx

SKF_HOME="/skf-flask"
cd ${SKF_HOME}/installations/local
sudo -u skf HOME=${SKF_HOME} ./wrapper.sh

DUMMY="/tmp/xxx"
touch "${DUMMY}"
tail -f "${DUMMY}"

