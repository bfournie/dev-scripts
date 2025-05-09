#!/usr/bin/env bash
# shellcheck source=/dev/null
set -euxo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

source "$SCRIPTDIR"/common.sh

while read line
do
    ip=$( echo "$line" | cut -d " " -f 1)
    host=$( echo "$line" | cut -d " " -f 2)
    echo "Trying to gather agent logs on host ${host}"
    if ssh -n -o 'ConnectTimeout=30' -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile=/dev/null' core@"${ip}" agent-gather -O >agent-gather-"${host}".tar.xz; then
        echo "Agent logs saved to agent-gather-"${host}".tar.xz" >&2
    else
        if [ $? == 127 ]; then
            echo "Skipping gathering agent logs, agent-gather script not present on host ${host}." >&2
        fi
        rm agent-gather-"${host}".tar.xz
    fi
done < "${OCP_DIR}"/hosts

num_screenshots=$(find "${OCP_DIR}" -type f -name "*.ppm" | wc -l)
if [[ "$num_screenshots" -gt 0 ]]; then
    archive_name="agent-gather-console-screenshots.tar.xz"
    echo "Gathering console screenshots to $archive_name"
    tar -cJf $archive_name ${OCP_DIR}/*.ppm
else
    echo "No console screenshots found. Skipping screenshot gather."
fi
