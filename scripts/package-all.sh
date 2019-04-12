#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PLUGINSBASE=${DIR}"/../wp/wp-content/plugins/"

rm -rf ${DIR}/../*.zip

${DIR}/package-theme.sh && \
(
    cd ${PLUGINSBASE};
    for pluginName in `ls | grep klarity`; do
        ${DIR}/package-plugin.sh `realpath ${PLUGINSBASE}${pluginName}` || exit 1;
    done
)
