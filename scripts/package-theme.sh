#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
theme_path=wp/wp-content/themes/klarity
archive_name=klarity.zip
archive_final_path=${DIR}/../${archive_name}

set -e

echo "Generating theme CSS..."
(
    cd ${theme_path}
    npm install
    npm run build
    dos2unix node_modules/materialize-css/dist/css/materialize*.css
    echo "Generating ZIP..."
    rm -f ${archive_name}
    git archive -9 -o ${archive_name} HEAD
    echo "Adding theme CSS and node_modules to ZIP..."
    zip -rv ${archive_name} \
        node_modules/materialize-css/dist/js/materialize.min.js \
        node_modules/materialize-css/sass \
        *.css \
     > /dev/null
    echo "Remove some dev files from ZIP..."
    zip -d ${archive_name} .gitignore package.json package-lock.json phpcs.xml.dist
 )
\
mv ${theme_path}/${archive_name} ${archive_final_path}
echo "The ZIP file was generated in `pwd ${archive_final_path}`"
