#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
rootfolder=$1

echo "Building plugins"
echo "========================="
cd ${DIR}/../${rootfolder}/wp-content/plugins
for pluginName in `ls | grep klarity`; do
    (\
        cd ${pluginName}
        echo -e "Building $pluginName..."
        if [ -f package.json ]; then
            npm install
            npm run build
            echo -e "$pluginName has been built."
        else
            echo -e "$pluginName wasn't built because it doesn't have a package.json"
        fi
    )
done
