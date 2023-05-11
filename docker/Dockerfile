# to do: pin to version
FROM alpine 

RUN apk add --update --no-cache openldap openldap-back-mdb openldap-back-monitor openldap-clients bash ca-certificates curl jq git

# RUN install -m 755 -o ldap -g ldap -d /etc/openldap/slapd.d
RUN install -m 755 -d /etc/openldap/slapd.d

# clone rbac repo
RUN git clone https://github.com/ministryofjustice/hmpps-ndelius-rbac.git /rbac

# Removing default db
# RUN rm /etc/openldap/slapd.d/cn=config/olcDatabase={2}hdb.ldif

COPY slapd /bootstrap/

# to do: add custom configuration from bootstrap
RUN slapadd -n 0 -F /etc/openldap/slapd.d -l /etc/openldap/slapd.ldif
# RUN chown -R ldap:ldap /etc/openldap/slapd.d/*

COPY ./entrypoint.sh /entrypoint.sh
RUN set -ex && chmod +x /entrypoint.sh

ARG LDAP_PORT=389
EXPOSE $LDAP_PORT

ENTRYPOINT ["bash", "/entrypoint.sh"]
