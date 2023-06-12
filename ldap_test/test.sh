#! /bin/bash

ldapsearch -L -x -D "cn=root,dc=moj,dc=com" -w ${BIND_PASSWORD} -H "ldap://delius-core-openldap-nlb-031548f823b8589d.elb.eu-west-2.amazonaws.com:389" -b "ou=Users,dc=moj,dc=com" -s sub "(&(cn=George*)(objectClass=person))"
