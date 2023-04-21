echo "starting openldap"
echo $SLAPD_LOG_LEVEL
env
exec slapd -h "ldap://${LDAP_HOST}:${LDAP_PORT}/ ldapi://${LDAP_HOST}" -u ldap -g ldap -d "${SLAPD_LOG_LEVEL}"