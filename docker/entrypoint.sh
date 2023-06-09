set -e

echo "starting openldap"
echo $SLAPD_LOG_LEVEL

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

if [ ! -f /var/lib/openldap/openldap-data/data.mdb ]; then
    LDAP_EMPTY="true"
    echo "OpenLDAP is empty. will restore from backup file after slapd stops"
else
    LDAP_EMPTY="false"
    echo "mdb file is present. will not restore from backup file"
fi

echo "LDAP_EMPTY RESULT: ${LDAP_EMPTY}"

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

echo "Schemas loaded"

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

if [ "$LDAP_EMPTY" == "true" ]; then
    echo "Loading backup ldif file from s3"
    if aws s3 cp ${MIGRATION_S3_LOCATION} /seed.ldif; then
        echo "S3 pull succeeded"

        echo "Adding seed ldif to ldap tree"
        slapadd -n 2 -F /etc/openldap/slapd.d -l /seed.ldif
        echo "Starting slapd with seeded data"
        # Replace this shell session with slapd so that it is PID 1
        exec slapd -F /etc/openldap/slapd.d -h "ldap://${IP}:${LDAP_PORT}/ ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi" -d $SLAPD_LOG_LEVEL
    else
        echo "S3 pull failed"
        echo "Remove mdb open-ldap data directory to reseed data"
    fi
else
    echo "LDAP data directory contains an mdb file. Did not seed data."
    echo "about to start slapd"
        # Replace this shell session with slapd so that it is PID 1
    exec slapd -F /etc/openldap/slapd.d -h "ldap://${IP}:${LDAP_PORT}/ ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi" -d $SLAPD_LOG_LEVEL
fi