#!/bin/bash
# Start slapd in the background
slapd -F /etc/openldap/slapd.d -h "ldap://${LDAP_HOST}:${LDAP_PORT}/ ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi" &
while true; do
  sleep 0.1
  echo 'wait'
  ldapsearch -x -H ldap://${IP}:${LDAP_PORT} -b "" -s base "(objectclass=*)" namingContexts > /dev/null 2>&1 && break
done
