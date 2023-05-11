set -e

echo "starting openldap"
echo $SLAPD_LOG_LEVEL
JSON=$(curl ${ECS_CONTAINER_METADATA_URI}/task)
IP=$($JSON | jq -r '.Containers[0].Networks[0].IPv4Addresses[0]')
echo $IP

# fix perms
chown -R openldap:openldap /var/run/slapd
chown -R openldap:openldap /var/lib/ldap
chown -R openldap:openldap /etc/ldap
chown -R openldap:openldap /etc/openldap/slapd

# start slapd
slapd -h "ldap://localhost:${LDAP_PORT}/ ldap://${IP}:${LDAP_PORT}/ ldapi:///" -d "${SLAPD_LOG_LEVEL}" -s "${SLAPD_LOG_LEVEL}" -u openldap -g openldap

# Hash the bind password
slappasswd -h {SSHA} -s $BIND_PASSWORD

# Load the bootstrap ldif files
ldapmodify -Y EXTERNAL -H ldapi:/// -f /bootstrap/config.ldif
ldapmodify -Y EXTERNAL -H ldapi:/// -f /bootstrap/db.ldif
ldapmodify -Y EXTERNAL -H ldapi:/// -f /bootstrap/overlays.ldif

# load the delius rbac ldif files
ldapadd -Y EXTERNAL -H ldapi:/// -f /rbac/hmpps-ndelius-rbac/schemas/delius.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /rbac/hmpps-ndelius-rbac/schemas/pwm.ldif

# Load default schemas
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/java.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/ppolicy.ldif
