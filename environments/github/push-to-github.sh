#!/bin/bash
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../.."
set -e

cd ${ROOTDIR}
(
    cd wp/wp-content/plugins
    for pluginName in `ls | grep klarity`; do
        pluginVersion=`grep -i "Version:" ${pluginName}/plugin.php | awk -F' ' '{print $NF}' | tr -d '\r'`
        repoName=wp-plugin-`echo ${pluginName} | sed 's/klarity-//g'`
        remoteName=github-${repoName}
        git remote remove ${remoteName}
        git remote add ${remoteName} git@github.com:Klarityorg/${repoName}.git
        (cd ${ROOTDIR}
         git tag -d ${pluginVersion} 2>/dev/null || true
         git tag ${pluginVersion}
         git push --tags --force ${remoteName} `git subtree split --prefix wp/wp-content/plugins/${pluginName} master`:master)
    done
)
(
    cd wp/wp-content/themes/klarity
    repoName=wp-theme-klarity
    remoteName=github-${repoName}
    git remote remove ${remoteName}
    git remote add ${remoteName} git@github.com:Klarityorg/${repoName}.git
    (cd ${ROOTDIR} && git subtree push --prefix wp/wp-content/themes/klarity ${remoteName} master)
)
