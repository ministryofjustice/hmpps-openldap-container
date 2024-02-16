#!/usr/bin/env bash

set +x

today=$(date '+%Y%m%d000000Z')

# Lock users that are not locked and endDate < today, or startDate > today
ldapmodify -Q -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi <<EOF
$(ldapsearch -Q -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -LLL -s one -b 'ou=Users,dc=moj,dc=com' \
"(&("'!'"(pwdAccountLockedTime=*))(|(&(endDate=*)("'!'"(endDate>=${today})))(&(startDate=*)("'!'"(startDate<=${today})))))" \
cn | \
sed 's/cn: .*/changetype: modify\nreplace: pwdAccountLockedTime\npwdAccountLockedTime: 000001010000Z/')
EOF

# Unlock users that are locked and endDate >= today and startDate <= today
ldapmodify -Q -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi <<EOF
$(ldapsearch -Q -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -LLL -s one -b 'ou=Users,dc=moj,dc=com' \
"(&(pwdAccountLockedTime=000001010000Z)(|("'!'"(endDate=*))(endDate>=${today}))(|("'!'"(startDate=*))(startDate<=${today})))" \
cn | \
sed 's/cn: .*/changetype: modify\ndelete: pwdAccountLockedTime\npwdAccountLockedTime: 000001010000Z/')
EOF