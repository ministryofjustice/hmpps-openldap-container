echo "starting openldap"
echo $SLAPD_LOG_LEVEL
curl 169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
exec slapd -h "ldap://${LDAP_HOST}:${LDAP_PORT}/ ldapi://${LDAP_HOST}" -u ldap -g ldap -d "${SLAPD_LOG_LEVEL}"