# to do: pin to version
FROM alpine:3.17

# Send TCP keepalive packets after 5 minutes (NLB idle timeout is 350 seconds)
RUN echo 300 > /proc/sys/net/ipv4/tcp_keepalive_time

RUN apk add --update --no-cache openldap openldap-back-mdb openldap-back-monitor openldap-clients openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint bash ca-certificates curl jq git aws-cli

RUN install -m 755 -d -o ldap -g ldap /etc/openldap/slapd.d && install -m 755 -o ldap -g ldap -d /var/lib/openldap/run && install -m 750 -o ldap -g ldap -d /var/lib/openldap/openldap-data

RUN rm /etc/openldap/slapd.conf /etc/openldap/slapd.ldif
RUN touch /var/lib/openldap/run/slapd.pid
COPY initial_config/slapd.ldif /etc/openldap/slapd.ldif

COPY delius_config /bootstrap/

# For local testing purposes, you should copy the ldif into the root as below (or mount it as a docker volume) and set the ENV Var LOCAL=true to disable s3 pulls
# COPY local_seed.ldif /local_seed.ldif

# added new ENV var to allow selecting a specific version of the rbac repo
ARG RBAC_TAG="master"

# clone rbac repo 
RUN git clone --depth 1 --branch ${RBAC_TAG} https://github.com/ministryofjustice/hmpps-ndelius-rbac.git /rbac && apk del git && chown -R ldap:ldap /bootstrap /rbac

RUN slapadd -n 0 -F /etc/openldap/slapd.d -l /etc/openldap/slapd.ldif

COPY ./entrypoint.sh /entrypoint.sh
RUN set -ex && chmod +x /entrypoint.sh

EXPOSE 389/tcp
EXPOSE 389/udp

ENTRYPOINT ["bash", "/entrypoint.sh"]
