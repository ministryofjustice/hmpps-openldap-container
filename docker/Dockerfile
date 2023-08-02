# to do: pin to version
FROM alpine:3.17

ENV LDAP_HOST=0.0.0.0
ENV LDAP_PORT=389
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache openldap openldap-back-mdb openldap-back-monitor openldap-clients openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint bash ca-certificates curl jq git aws-cli python3

RUN install -m 755 -d -o ldap -g ldap /etc/openldap/slapd.d && install -m 755 -o ldap -g ldap -d /var/lib/openldap/run && install -m 750 -o ldap -g ldap -d /var/lib/openldap/openldap-data
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools Jinja2

RUN rm /etc/openldap/slapd.conf /etc/openldap/slapd.ldif
RUN touch /var/lib/openldap/run/slapd.pid
COPY initial_config/slapd.ldif /etc/openldap/slapd.ldif

COPY delius_config /bootstrap/

# For local testing purposes, you should copy the ldif into the root as below and set the ENV Var LOCAL=true
# COPY local_seed.ldif /local_seed.ldif

# clone rbac repo 
RUN git clone https://github.com/ministryofjustice/hmpps-ndelius-rbac.git /rbac && apk del git && chown -R ldap:ldap /bootstrap /rbac

RUN slapadd -n 0 -F /etc/openldap/slapd.d -l /etc/openldap/slapd.ldif

# Wait for slapd to start by continually trying to connect to it
COPY start_ldap.sh /start_ldap.sh
RUN chmod +x /start_ldap.sh && ./start_ldap.sh && \
  # Loading bootstrap ldif file 1
  ldapmodify -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /bootstrap/config.ldif && \
  # Load the bootstrap schemas
  ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /etc/openldap/schema/cosine.ldif && \
  ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /etc/openldap/schema/nis.ldif && \
  ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /etc/openldap/schema/inetorgperson.ldif && \
  ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /etc/openldap/schema/java.ldif 
# Loading bootstrap overlays - currently failing all operations returning ldap_add No such object (32)
# ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /bootstrap/overlays.ldif



# echo "Loading bootstrap ldif file 2"
# ldapadd -Y EXTERNAL -H ldapi://%2Fvar%2Flib%2Fopenldap%2Frun%2Fldapi -f /bootstrap/db.ldif

# Tidy up
# TO DO

COPY ./entrypoint.sh /entrypoint.sh
RUN set -ex && chmod +x /entrypoint.sh

EXPOSE 389/tcp
EXPOSE 389/udp

ENTRYPOINT ["bash", "/entrypoint.sh"]
