# hmpps-openldap-container

# Vars

```
# Host to listen on for connections on LDAP_PORT
LDAP_HOST="0.0.0.0"
# Log level for slapd - see https://www.openldap.org/doc/admin24/slapdconfig.html Table 6.1: Debugging Levels
SLAPD_LOG_LEVEL="-1"
# Port to serve slapd on
LDAP_PORT=389
# S3 URI for seed ldif file
MIGRATION_S3_LOCATION=s3://<bucket>/seed.ldif"
# Password assigned to the root user
BIND_PASSWORD=secure_password
```
