set -e

echo "starting openldap"
echo $SLAPD_LOG_LEVEL

IP=$LDAP_HOST
BASE_ROOT_DC="${BASE_ROOT%%,*}"
BASE_USERS_OU="${BASE_USERS%%,*}"
BASE_GROUPS_OU="${BASE_GROUPS%%,*}"
BIND_ADMIN_USER_CN="${BIND_ADMIN_USER%%,*}"

# Hash the bind passwords for root and admin user
HASHED_BIND_ROOT_PASSWORD=$(slappasswd -h {SSHA} -s $BIND_ROOT_PASSWORD)
HASHED_BIND_ADMIN_PASSWORD=$(slappasswd -h {SSHA} -s $BIND_ADMIN_PASSWORD)

# Replace the bind password in the bootstrap ldif files
sed -i "s_HASHEDPASSWORD_${HASHED_BIND_ROOT_PASSWORD}_g" /bootstrap/db.ldif

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

# load the delius rbac ldif files - context
cp /rbac/context.ldif.j2 rbac/context.ldif
sed -i "s/{{ ldap_config.base_root }}/${BASE_ROOT}/g" /rbac/context.ldif
sed -i "s/{{ ldap_config.base_root | .* }}/${BASE_ROOT_DC}/g" /rbac/context.ldif
sed -i "s/{{ ldap_config.base_users }}/${BASE_USERS}/g" /rbac/context.ldif
sed -i "s/{{ ldap_config.base_users | .* }}/${BASE_USERS_OU}/g" /rbac/context.ldif
sed -i "s/{{ ldap_config.base_groups }}/${BASE_GROUPS}/g" /rbac/context.ldif
sed -i "s/{{ ldap_config.base_groups | .* }}/${BASE_GROUPS_OU}/g" /rbac/context.ldif
sed -i "s/{{ ldap_config.bind_user }}/${BIND_ADMIN_USER}/g" /rbac/context.ldif
sed -i "s/{{ ldap_config.bind_user | .* }}/${BIND_ADMIN_USER_CN}/g" /rbac/context.ldif
# echo $HASHED_BIND_ADMIN_PASSWORD
# sed -i "s/{{ bind_password_hash.stdout }}/${HASHED_BIND_ADMIN_PASSWORD}/g" /rbac/context.ldif
ldapadd -Y EXTERNAL -Q -H ldapi:/// -c -f /rbac/context.ldif || echo "Unable to apply context changes"
# rm -rf rbac/context.ldif

# load the delius rbac ldif files - policies
# TO DO

# load the delius rbac ldif files - schemas
ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /rbac/schemas/delius.ldif
ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /rbac/schemas/pwm.ldif

# load the delius rbac ldif files - roles
# TO DO

# load the delius rbac ldif files - groups
# TO DO

# load the delius rbac ldif files - users
# TO DO

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
        # Replace this shell session with slapd so that it is PID 1
        exec slapd -F /etc/openldap/slapd.d -h "ldap://${IP}:${LDAP_PORT}/ ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi" -d $SLAPD_LOG_LEVEL
    else
        echo "Loading backup ldif file from s3"
        if aws s3 cp ${MIGRATION_S3_LOCATION} /seed.ldif; then
            echo "S3 pull succeeded"

            echo "Adding seed ldif to ldap tree"
            slapadd -v -n 2 -F /etc/openldap/slapd.d -l /seed.ldif
            echo "Starting slapd with seeded data"
            # Replace this shell session with slapd so that it is PID 1
            exec slapd -F /etc/openldap/slapd.d -h "ldap://${IP}:${LDAP_PORT}/ ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi" -d $SLAPD_LOG_LEVEL
        else
            echo "S3 pull failed"
            echo "Remove mdb open-ldap data directory to reseed data"
            exit 1
        fi
    fi
else
    echo "LDAP data directory contains an mdb file. Did not seed data." 
    echo "Please verify this data is correct"
    echo "about to start slapd"
        # Replace this shell session with slapd so that it is PID 1
    exec slapd -F /etc/openldap/slapd.d -h "ldap://${IP}:${LDAP_PORT}/ ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi" -d $SLAPD_LOG_LEVEL
fi
