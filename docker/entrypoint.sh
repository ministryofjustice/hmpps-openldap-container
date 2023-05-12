set -e

echo "starting openldap"
echo $SLAPD_LOG_LEVEL
if [[ -v ECS_CONTAINER_METADATA_URI ]]; then
    JSON=$(echo curl -s ${ECS_CONTAINER_METADATA_URI}/task)
    IP=$($JSON | jq -r '.Containers[0].Networks[0].IPv4Addresses[0]')
    echo $IP
else
    IP="127.0.0.1"
    echo $IP
fi

# awk -F: '{ print $1}' /etc/passwd

echo $(ps -eaf)

echo $(printenv)
mkdir -p /run/openldap/

# if [[ ! -f /etc/openldap/slapd.conf ]]; then
# 	touch /etc/openldap/slapd.conf
# fi

if [[ ! -f /var/lib/openldap/run/slapd.pid ]]; then
    mkdir -p /var/lib/openldap/run
	touch /var/lib/openldap/run/slapd.pid
fi

# sed -i "s_\.la_\.so_g" /etc/openldap/slapd.conf

echo "Configuring OpenLDAP via slapd.d"
mkdir -p /etc/openldap/slapd.d
chmod -R 750 /etc/openldap/slapd.d
mkdir -p /var/lib/openldap/openldap-data
chmod -R 750 /var/lib/openldap/openldap-data


echo $(ps -eaf)

# Hash the bind password
HASHED_BIND_PASSWORD=$(slappasswd -h {SSHA} -s $BIND_PASSWORD)
echo $HASHED_BIND_PASSWORD
# Replace the bind password in the bootstrap ldif files
sed -i "s_HASHEDPASSWORD_${HASHED_BIND_PASSWORD}_g" /bootstrap/db.ldif

slapd -F /etc/openldap/slapd.d -h "ldap://${IP}:${LDAP_PORT}/ ldapi://%2Frun%2Fopenldap%2Fldapi" &

echo $(ps)
echo "Waiting for OpenLDAP to start"
while true; do
    sleep 0.1
    echo 'wait'
    ldapsearch -x -H ldap://${IP}:${LDAP_PORT} -b "" -s base "(objectclass=*)" namingContexts > /dev/null 2>&1 && break
done

echo "Loading bootstrap default schemas"
ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f /etc/openldap/schema/inetorgperson.ldif
ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f /etc/openldap/schema/java.ldif
# ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f /etc/openldap/schema/ppolicy.ldif

# Load the bootstrap ldif files
echo "Loading bootstrap ldif file 1"
ldapmodify -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f /bootstrap/config.ldif
echo "Loading bootstrap ldif file 2"
ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f /bootstrap/db.ldif
echo "Loading bootstrap ldif file 3"
ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f /bootstrap/overlays.ldif

# load the delius rbac ldif files
ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f /rbac/schemas/delius.ldif
ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f /rbac/schemas/pwm.ldif

kill $(cat /var/run/openldap/slapd.pid)

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

exec slapd -F /etc/openldap/slapd.d -h "ldap://${IP}:${LDAP_PORT}/ ldapi://%2Frun%2Fopenldap%2Fldapi" -d $SLAPD_LOG_LEVEL
