#!/usr/bin/env bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null 2>&1 && pwd )"
. ${ROOT_DIR}/environments/production/.env

ssh -p ${JESUISANAS_SSH_PORT} -t ${JESUISANAS_SSH_USER}@${JESUISANAS_SITE}.seravo.com "mysqldump -u$JESUISANAS_DB_USER -p$JESUISANAS_DB_PASSWORD $JESUISANAS_DB_NAME" \
    | sed 's~https://jesuisanas.org~http://localhost:8000~g' \
    > ${ROOT_DIR}/dump.sql \
&& (cd ${ROOT_DIR} && docker-compose -f environments/local/docker-compose-dev.yml exec -T db mysql -uwordpress -pwordpress wordpress < dump.sql) \
\
&& scp -r -P ${JESUISANAS_SSH_PORT} ${JESUISANAS_SSH_USER}@${JESUISANAS_SITE}.seravo.com:/data/wordpress/htdocs/wp-content/uploads ${ROOT_DIR}/wp/wp-content/
