#!/bin/bash

join_by() {
  local d="${1-}" f="${2-}"
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

users=$(grep '^dn: cn=[^,]*,ou=Users' testusers.ldif | sed -E 's/^dn: cn=([^,]*),.*/\1/')

for username in $users; do
    dn=cn=$username,ou=Users,dc=moj,dc=com
    echo Deleting user $dn...
    ldapdelete -Y external -Q -H ldapi:// -r "$dn"
done

echo Adding users...
ldapadd -Y external -Q -H ldapi:// -f testusers.ldif -c

echo Removing email and password from all other users...
joined=$(join_by ')(cn=' ${users[@]})
exclude_test_user_filter='(!(|(cn='"${joined})))"
ldap_password=$(aws ssm get-parameter --name '/delius-pre-prod/delius/apacheds/apacheds/ldap_admin_password' --with-decryption --query Parameter.Value --output text --region eu-west-2)
ldapsearch -D cn=root,dc=moj,dc=com -w "$ldap_password" -b ou=Users,dc=moj,dc=com -s one -LLL "$exclude_test_user_filter" dn \
| sed -E 's/^(dn:.*)/\1\nchangetype: modify\ndelete: mail\n\n\1\nchangetype: modify\ndelete: userPassword/' \
| ldapmodify -Y external -Q -H ldapi:// -c
