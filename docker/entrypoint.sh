echo "starting openldap"
echo $SLAPD_LOG_LEVEL
JSON=$(curl ${ECS_CONTAINER_METADATA_URI}/task)
echo IP=$($JSON | jq -r '.Containers[0].Networks[0].IPv4Addresses[0]')
# nslookup all 3 expected containers
# remove $IP from list of nodes
# set other master replicas to remaining IPs


slappasswd -h {SSHA} -s $BIND_PASSWORD
ldapmodify -Y EXTERNAL -H ldapi:/// -f /bootstrap//config.ldif
ldapmodify -Y EXTERNAL -H ldapi:/// -f /bootstrap//db.ldif
ldapmodify -Y EXTERNAL -H ldapi:/// -f /bootstrap//overlays.ldif

ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/java.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/ppolicy.ldif

exec slapd -h "ldap://${LDAP_HOST}:${LDAP_PORT}/ ldapi://${LDAP_HOST}" -u ldap -g ldap -d "${SLAPD_LOG_LEVEL}"