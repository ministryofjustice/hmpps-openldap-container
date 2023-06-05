set -e

echo "starting openldap"
echo $SLAPD_LOG_LEVEL
# if [[ -v ECS_CONTAINER_METADATA_URI ]]; then
#     JSON=$(echo curl -s ${ECS_CONTAINER_METADATA_URI}/task)
#     IP=$($JSON | jq -r '.Containers[0].Networks[0].IPv4Addresses[0]')
#     echo $IP
# else
#     IP="127.0.0.1"
#     echo $IP
# fi

IP=$LDAP_HOST
echo "will server on ${IP}"
# Hash the bind password
HASHED_BIND_PASSWORD=$(slappasswd -h {SSHA} -s $BIND_PASSWORD)
# Replace the bind password in the bootstrap ldif files
sed -i "s_HASHEDPASSWORD_${HASHED_BIND_PASSWORD}_g" /bootstrap/db.ldif

# Start slapd in the background
slapd -F /etc/openldap/slapd.d -h "ldap://${IP}:${LDAP_PORT}/ ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi" &

# Wait for slapd to start by continually trying to connect to it
echo "Waiting for OpenLDAP to start"
while true; do
    sleep 0.1
    echo 'wait'
    ldapsearch -x -H ldap://${IP}:${LDAP_PORT} -b "" -s base "(objectclass=*)" namingContexts > /dev/null 2>&1 && break
done


if ldapsearch -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -b "ou=Users,dc=moj,dc=com" -s SUB "(objectclass=person)" | grep -q 'numEntries:'; then
    LDAP_EMPTY=0
else
    LDAP_EMPTY=1
    echo "OpenLDAP is empty. will restore from backup file after slapd stops"
fi

if [[ $LDAP_EMPTY -eq 1 ]]; then
    echo "OpenLDAP is empty. loading bootstrap files"
    echo "Loading bootstrap ldif file 1"
    ldapmodify -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /bootstrap/config.ldif
    echo "Loading bootstrap ldif file 2"
    ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /bootstrap/db.ldif

    # Load the bootstrap schemas
    echo "Loading bootstrap default schemas"
    ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /etc/openldap/schema/cosine.ldif
    ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /etc/openldap/schema/nis.ldif
    ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /etc/openldap/schema/inetorgperson.ldif
    ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /etc/openldap/schema/java.ldif

    # Load the bootstrap ldif files
    echo "Loading bootstrap ldif file 3"
    ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /bootstrap/overlays.ldif

    # load the delius rbac ldif files
    ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /rbac/schemas/delius.ldif
    ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /rbac/schemas/pwm.ldif
fi

echo "schemas loaded"

kill $(cat /var/run/openldap/slapd.pid)

# Wait for slapd to stop
echo "Waiting for OpenLDAP to stop"
while true; do
    sleep 0.1
    if ldapsearch -x -H ldap://${IP}:${LDAP_PORT} -b "" -s base "(objectclass=*)" namingContexts > /dev/null 2>&1; then
        echo "OpenLDAP is running"       
    else
        echo "OpenLDAP is not running"
        break
    fi
done

if [[ $LDAP_EMPTY -eq 1 ]]; then
    echo "Loading backup ldif file"
    slapadd -n 2 -F /etc/openldap/slapd.d -l /backup.ldif
fi

echo "about to start slapd"
# Replace this shell session with slapd so that it is PID 1
exec slapd -F /etc/openldap/slapd.d -h "ldap://${IP}:${LDAP_PORT}/ ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi" -d $SLAPD_LOG_LEVEL
