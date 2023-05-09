echo "starting openldap"
echo $SLAPD_LOG_LEVEL
JSON=$(curl ${ECS_CONTAINER_METADATA_URI}/task)
echo $JSON | jq -r '.Containers[0].Networks[0].IPv4Addresses[0]'
exec slapd -h "ldap://${LDAP_HOST}:${LDAP_PORT}/ ldapi://${LDAP_HOST}" -u ldap -g ldap -d "${SLAPD_LOG_LEVEL}"