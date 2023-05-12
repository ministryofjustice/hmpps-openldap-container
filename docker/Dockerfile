# to do: pin to version
FROM alpine:3.17

RUN apk add --update --no-cache openldap openldap-back-mdb openldap-back-monitor openldap-clients openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint bash ca-certificates curl jq git

# RUN install -m 755 -o ldap -g ldap -d /etc/openldap/slapd.d
RUN install -m 755 -d /etc/openldap/slapd.d
RUN rm /etc/openldap/slapd.conf
RUN rm /etc/openldap/slapd.ldif
COPY slapd/slapd.ldif /etc/openldap/slapd.ldif
RUN install -m 755 -o ldap -g ldap -d /var/lib/openldap/run
RUN chown -R ldap:ldap /etc/openldap/slapd.d
# clone rbac repo
RUN git clone https://github.com/ministryofjustice/hmpps-ndelius-rbac.git /rbac

# Removing default db
# RUN rm /etc/openldap/slapd.d/cn=config/olcDatabase={2}hdb.ldif

COPY slapd /bootstrap/

COPY ./entrypoint.sh /entrypoint.sh
RUN set -ex && chmod +x /entrypoint.sh

RUN chown -R ldap:ldap /bootstrap
RUN chown -R ldap:ldap /rbac

# to do: add custom configuration from bootstrap
RUN slapadd -n 0 -F /etc/openldap/slapd.d -l /etc/openldap/slapd.ldif

ARG LDAP_PORT=389
EXPOSE $LDAP_PORT

ENTRYPOINT ["bash", "/entrypoint.sh"]
