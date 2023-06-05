# to do: pin to version
FROM alpine:3.18

# RUN apk add --update --no-cache openldap openldap-back-mdb openldap-back-monitor openldap-clients openldap-overlay-memberof openldap-overlay-ppolicy openldap-overlay-refint bash ca-certificates curl jq git
ARG VERSION=2.5.14

RUN apk add --update --no-cache bash ca-certificates curl jq git tar openssl cyrus-sasl build-base groff pkgconfig libtool

RUN mkdir /source && curl https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-${VERSION}.tgz -o /source/openldap-${VERSION}.tgz

WORKDIR /source

RUN gunzip -c openldap-${VERSION}.tgz | tar xf -

WORKDIR /source/openldap-${VERSION}

RUN CPPFLAGS="-I/usr/bin/openssl" LIBS="-L/usr/lib" ./configure \
    --enable-ppolicy=mod \
    --enable-refint=mod \
    --enable-memberof=mod \
    --enable-modules \
    --enable-slapd \
    --enable-slapi \
    --enable-dnssrv=mod \
    --enable-ldap=mod \
    --enable-mdb=mod \
    --enable-passwd=mod \
    --enable-meta=mod \
    --enable-asyncmeta=mod \
    --enable-null=mod \
    --enable-passwd=mod \
    --enable-relay=mod \
    --enable-sock=mod \
    --enable-overlays=mod \
    --with-cyrus-sasl \
    --with-tls=openssl \
    --enable-argon2

RUN make depend && make && make install

# RUN install -m 755 -o ldap -g ldap -d /etc/openldap/slapd.d
RUN install -m 755 -d /usr/local/etc/openldap/slapd.d

# RUN rm /etc/openldap/slapd.conf /etc/openldap/slapd.ldif
# RUN touch /var/lib/openldap/run/slapd.pid
COPY initial_config/slapd.ldif /usr/local/etc/openldap/slapd.ldif

# RUN wget -O /etc/openldap/schema/ppolicy.schema https://raw.githubusercontent.com/openldap/openldap/master/servers/slapd/schema/ppolicy.schema

COPY delius_config /bootstrap/
# clone rbac repo
RUN git clone https://github.com/ministryofjustice/hmpps-ndelius-rbac.git /rbac && apk del git

RUN slapadd -n 0 -F /usr/local/etc/openldap/slapd.d -l /usr/local/etc/openldap/slapd.ldif

COPY ./entrypoint.sh /entrypoint.sh
RUN set -ex && chmod +x /entrypoint.sh

EXPOSE 389/tcp
EXPOSE 389/udp

ENTRYPOINT ["bash", "/entrypoint.sh"]
