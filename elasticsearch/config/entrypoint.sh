#!/bin/bash

set -m

# Add elasticsearch as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- elasticsearch "$@"
fi

if [ "$NODE_NAME" = "" ]; then
	export NODE_NAME=$HOSTNAME
fi


if [ "x${ELASTICSEARCH_URL}" = "x" ]; then
  el_url="https://elasticsearch:9200"
else
  el_url="${ELASTICSEARCH_URL}"
fi

#cat /elasticsearch/config/elasticsearch.yml

# chown -R 700 /elasticsearch/config
#:q

# Run as user "elasticsearch" if the command is "elasticsearch"
if [ "$1" = 'elasticsearch' -a "$(id -u)" = '0' ]; then
	set -- su-exec eulasticsearch "$@"
	ES_JAVA_OPTS="-Des.network.host=$NETWORK_HOST -Des.logger.level=$LOG_LEVEL -Xms$HEAP_SIZE -Xmx$HEAP_SIZE"  $@ &
else
	$@ &
fi


#until curl -XGET $el_url; do
#  >&2 echo "Elastic is unavailable - sleeping"
#  sleep 5
#done

#>&2 echo "Elastic is up - executing command"
#/run/wait_until_started.sh
chmod a+x /usr/share/elasticsearch/plugins/search-guard-6/tools/install_demo_configuration.sh

#echo "Y " | /usr/share/elasticsearch/plugins/search-guard-6/tools/install_demo_configuration.sh

#su -c "elasticsearch -d" elasticsearch
/usr/share/elasticsearch/plugins/search-guard-6/tools/install_demo_configuration.sh -y


su -c "elasticsearch &" elasticsearch


cat /usr/share/elasticsearch/config/elasticsearch.yml
cat /sg_roles.yml > /usr/share/elasticsearch/plugins/search-guard-6/sgconfig/sg_roles.yml





until curl -k -XGET $el_url; do
  echo "Sleeping"
  >&2 echo "Elastic is unavailable - sleeping"
  sleep 5
done





chmod a+x /usr/share/elasticsearch/plugins/search-guard-6/tools/sgadmin.sh
/usr/share/elasticsearch/plugins/search-guard-6/tools/sgadmin.sh \
-cd /usr/share/elasticsearch/plugins/search-guard-6/sgconfig -icl -key \
/usr/share/elasticsearch/config/kirk-key.pem -cert /usr/share/elasticsearch/config/kirk.pem -cacert \
/usr/share/elasticsearch/config/root-ca.pem -h "${ELASTICSEARCH_URL}" -nhnv


#/run/wait_until_started.sh
curl -k -u admin:admin "$el_url/_searchguard/authinfo?pretty"





wazuhadmin_pwd=$(bash /usr/share/elasticsearch/plugins/search-guard-6/tools/hash.sh -p $WAZUHADMIN_PWD)

echo "
wazuhadmin:
  hash: $wazuhadmin_pwd
  roles:
    - wazuhadmin_role" >> /usr/share/elasticsearch/plugins/search-guard-6/sgconfig/sg_internal_users.yml 

cat /usr/share/elasticsearch/plugins/search-guard-6/sgconfig/sg_internal_users.yml 




echo "
sg_wazuh_admin:
  backendroles:
    - wazuhadmin_role" >> /usr/share/elasticsearch/plugins/search-guard-6/sgconfig/sg_roles_mapping.yml



/usr/share/elasticsearch/plugins/search-guard-6/tools/sgadmin.sh \
-cd /usr/share/elasticsearch/plugins/search-guard-6/sgconfig -icl -key \
/usr/share/elasticsearch/config/kirk-key.pem -cert /usr/share/elasticsearch/config/kirk.pem -cacert \
/usr/share/elasticsearch/config/root-ca.pem -h "${ELASTICSEARCH_URL}" -nhnv


#Insert default templates
cat /usr/share/elasticsearch/config/wazuh-elastic6-template-alerts.json | curl -k -u admin:admin -XPUT "https://127.0.0.1:9200/_template/wazuh" -H 'Content-Type: application/json' -d @-

pkill -f elasticsearch

#/run/auth/users.sh
#/run/auth/sgadmin.sh

su -c "elasticsearch " elasticsearch