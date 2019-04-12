#!/usr/bin/env bash
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." >/dev/null 2>&1 && pwd )"
pass=`grep -A1 WORDPRESS_DB_PASSWORD ${ROOT_DIR}/environments/k8s/wordpress-deployment.yaml | grep value | awk '{print $2}'`
. ${ROOT_DIR}/environments/production/.env

ssh -p ${JESUISANAS_SSH_PORT} -t ${JESUISANAS_SSH_USER}@${JESUISANAS_SITE}.seravo.com "mysqldump -u$JESUISANAS_DB_USER -p$JESUISANAS_DB_PASSWORD $JESUISANAS_DB_NAME" \
    | sed 's~https://jesuisanas.org~https://wp.jesuisanas.org~g' \
    > ${ROOT_DIR}/dump.sql \
&& scp -r -P ${JESUISANAS_SSH_PORT} ${JESUISANAS_SSH_USER}@${JESUISANAS_SITE}.seravo.com:/data/wordpress/htdocs/wp-content/uploads ${ROOT_DIR}/wp/wp-content/

pod=`kubectl get pods | grep jesuisanaswp | cut -d' ' -f1`
kubectl cp ${ROOT_DIR}/dump.sql ${pod}:/tmp/dump.sql \
&& kubectl exec -it ${pod} -- \
    sh -c "apt update >/dev/null 2>&1 && apt install -y mysql-client >/dev/null 2>&1 && mysql -ufortytwo_service -h 10.90.224.3 -p$pass wordpress < /tmp/dump.sql" \
&& kubectl cp ${ROOT_DIR}/wp/wp-content/uploads ${pod}:/var/www/html/wp-content
