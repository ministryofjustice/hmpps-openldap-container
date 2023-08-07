FROM alpine

# Basic tools for now
RUN apk add --update --no-cache bash ca-certificates curl jq git aws-cli openldap-clients python py-pip build-base libffi-dev openssl-dev

RUN pip install --upgrade pip && pip install git+https://github.com/ministryofjustice/hmpps-ldap-automation-cli.git@init-click

CMD ["ldap-automation"]