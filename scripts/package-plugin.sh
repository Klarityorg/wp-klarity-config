#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
plugin_path="$1"
if [[ -z "$plugin_path" ]]; then
    echo "Please specify the path of the plugin to package. Usage: $0 plugin_path"
    exit 1
fi

archive_path=$(realpath ${DIR}"/../"`basename ${plugin_path}`.zip)

echo "Building plugin..."
cd ${plugin_path}
if [ ! -f package.json ]; then
  echo "No package.json found"
else
  output=$(npm install && npm run build)
  if echo "$output" | grep -q 'Built successfully'; then echo "OK"; else echo "Build failed!"; exit 1; fi
fi
echo "Generating ZIP..."
zip -9 -r -x '*node_modules*' -x '*.git*' -o ${archive_path} .
echo "The ZIP file was generated in `${archive_path}`"
