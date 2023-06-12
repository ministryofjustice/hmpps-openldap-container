from ldap3 import Server, Connection, ALL, SUBTREE
import random
import os
import time

ldap_server = "ldap://localhost"
ldap_user = "cn=root,dc=moj,dc=com"
ldap_password = "password"
server = Server(ldap_server, get_info=ALL)

user_list = [
    "Emma",
    "Nicky",
    "Brian",
    "Debbie",
    "George",
    "John",
    "Paul",
    "Stuart",
    "Pete",
]
print("connecting")
for i in range(0, 10000000000):
    print("Run #" + str(i))
    conn = Connection(server, ldap_user, ldap_password, auto_bind=True, authentication="SIMPLE")
    conn.search(
        "ou=Users,dc=moj,dc=com",
        "(&(cn=" + random.choice(user_list) + "*)(objectClass=person))",
        search_scope=SUBTREE,
        attributes=["*"],
    )
    print(conn.entries)
    conn.unbind()
