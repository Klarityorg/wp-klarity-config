#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
rootfolder=$1

echo "Generating theme CSS"
echo "========================="
(cd ${DIR}/../${rootfolder}/wp-content/themes/klarity && (npm install && npm run build || exit 1))
