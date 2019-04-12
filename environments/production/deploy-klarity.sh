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
    git remote add ${remoteName} ssh://${KLARITY_SSH_USER}@${KLARITY_SITE}.seravo.com:${KLARITY_SSH_PORT}${remotePathRoot}/${remoteSubdir}
    git push ${remoteName} master
}

(addGitRemoteAndPush production-theme wp/wp-content/themes/klarity htdocs/wp-content/themes/klarity)
