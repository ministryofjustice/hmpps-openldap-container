from ldap3 import Server, Connection, ALL, SUBTREE
import random
import os

ldap_server = os.getenv("LDAP_SERVER")
ldap_user = "cn=root,dc=moj,dc=com"
ldap_password = os.getenv("BIND_PASSWORD")
server = Server(ldap_server, get_info=ALL)
print("Server: " + ldap_server)
print("User: " + ldap_user)
print("ldap server info: " + str(server.info))


for i in range(0, 10000000000):
    print("Run #" + str(i))
    conn = Connection(server, ldap_user, ldap_password, auto_bind=True, authentication="SIMPLE")
    conn.search(
        "ou=Users,dc=moj,dc=com",
        "(objectClass=*)",
        search_scope=SUBTREE,
        attributes=["*"],
    )
    print(conn.entries)
    conn.unbind()
