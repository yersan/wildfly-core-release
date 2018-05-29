#!/bin/bash

# Add local user wfcore
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}

echo "Starting with UID : $USER_ID"
useradd --shell /bin/bash -u $USER_ID -o -c "" -m wfcore
export HOME=/home/wfcore

chown -R wfcore:wfcore /home/wfcore/

exec /usr/local/bin/gosu wfcore "$@"