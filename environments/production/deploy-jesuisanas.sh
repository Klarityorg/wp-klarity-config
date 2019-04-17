#!/bin/bash
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../.."

set -e

. ${ROOTDIR}/environments/production/.env
cd ${ROOTDIR}

addGitRemoteAndPush() {
    remotePathRoot=/data/wordpress
    remoteName=$1
    localSubdir=$2
    remoteSubdir=$3

    cd ${ROOTDIR}/${localSubdir}

    git remote remove ${remoteName} || echo 'No such remote, ignoring'
    git remote add ${remoteName} ssh://${JESUISANAS_SSH_USER}@${JESUISANAS_SITE}.seravo.com:${JESUISANAS_SSH_PORT}${remotePathRoot}/${remoteSubdir}
    git push ${remoteName} master
}

# Update plugins on remote
#cd ${ROOTDIR}/wp/wp-content/plugins
#for pluginName in `ls | grep klarity-`; do
#    (addGitRemoteAndPush production-plugin-${pluginName} wp/wp-content/plugins/${pluginName} htdocs/wp-content/plugins/${pluginName})
#done

# Update theme on remote
(addGitRemoteAndPush production-theme wp/wp-content/themes/klarity htdocs/wp-content/themes/klarity)
