set -e

### Warm up cache ###
warmup_ldap_cache() {
    echo "Warming up LDAP cache..."
    echo "(1/4) Querying all users..."
    ldapsearch -x -H ldap://localhost -D "cn=root,dc=moj,dc=com" -w $BIND_PASSWORD -b "ou=users,dc=moj,dc=com" '+' '*' > /dev/null

    echo "(2/4) Querying all objects..."
    ldapsearch -x -H ldap://localhost -D "cn=root,dc=moj,dc=com" -w $BIND_PASSWORD -b "dc=moj,dc=com" "(objectClass=*)" uid cn mail > /dev/null

    echo "(3/4) Querying Roles/Associations for all users..."
    ldapsearch -x -H ldap://localhost -D "cn=root,dc=moj,dc=com" -w $BIND_PASSWORD -b "ou=users,dc=moj,dc=com" '(|(objectClass=NDRole)(objectClass=NDRoleAssociation))' '+' '*' > /dev/null

    echo "(4/4) Running some derefencing queries..."
    ldapsearch -H ldapi:// -Y EXTERNAL -Q -LLL -b "ou=Groups,dc=moj,dc=com" | grep -c ^dn:
    ldapsearch -H ldapi:// -Y EXTERNAL -Q -LLL -b "ou=Groups,dc=moj,dc=com" -a always | grep -c ^dn:
    ldapsearch -H ldapi:// -Y EXTERNAL -Q -LLL -b "ou=Groups,dc=moj,dc=com" -a never | grep -c ^dn:

    echo "Cache warmed up successfully."
}

start_slapd() {
    slapd -F /etc/openldap/slapd.d -h "ldap://${IP}:${LDAP_PORT}/ ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi" -d $SLAPD_LOG_LEVEL &

    echo "Waiting for OpenLDAP to start"
    while true; do
        sleep 0.1
        echo 'wait'
        ldapsearch -x -H ldap://${IP}:${LDAP_PORT} -b "" -s base "(objectclass=*)" namingContexts > /dev/null 2>&1 && break
    done

    warmup_ldap_cache

    SLAPD_PID=$(cat /var/run/openldap/slapd.pid)
    wait $SLAPD_PID
}

echo "starting openldap"
echo $SLAPD_LOG_LEVEL

IP=$LDAP_HOST

echo "RBAC tag is $RBAC_TAG"

echo "Cloning rbac repo..."
# clone rbac repo
git clone --depth 1 --branch ${RBAC_TAG} https://github.com/ministryofjustice/hmpps-ndelius-rbac.git /rbac && apk del git && chown -R ldap:ldap /rbac

echo "rbac repo cloned"

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
    if [ "$LOCAL" == "true" ]; then
        echo "Loading local seed ldif file"
        echo "Adding seed ldif to ldap tree"
        slapadd -n 2 -F /etc/openldap/slapd.d -l /local_seed.ldif
        echo "Starting slapd with seeded data"
        start_slapd
    else
        echo "Loading backup ldif file from s3"
        mkdir /tmp/seed
        if aws s3 cp ${MIGRATION_S3_LOCATION} /tmp/seed/$(basename "$MIGRATION_S3_LOCATION"); then
            echo "S3 pull succeeded"
            if [ -f /tmp/seed/$(basename "$MIGRATION_S3_LOCATION") ]; then
                # if file ends in gz, unzip it
                if [[ /tmp/seed/$(basename "$MIGRATION_S3_LOCATION") == *.gz ]]; then
                    echo "Extracting seed ldif file"
                    gunzip -c /tmp/seed/$(basename "$MIGRATION_S3_LOCATION") > /seed.ldif
                    echo "Extracted seed ldif file to /seed.ldif"
                else
                    echo "Seed ldif file not gzipped"
                    mv /tmp/seed/$(basename "$MIGRATION_S3_LOCATION") /seed.ldif
                    echo "Moved seed ldif file to /seed.ldif"
                fi
            else
                echo "Extracted seed ldif file not found"
                exit 1
            fi

            echo "Adding seed ldif to ldap tree"
            slapadd -v -n 2 -F /etc/openldap/slapd.d -l /seed.ldif
            echo "Starting slapd with seeded data"
            start_slapd
        else
            echo "S3 pull failed"
            echo "Remove mdb open-ldap data directory to reseed data"
            exit 1
        fi
    fi
else
    echo "LDAP data directory contains an mdb file. Did not seed data." 
    echo "Please verify this data is correct"
    start_slapd
fi
