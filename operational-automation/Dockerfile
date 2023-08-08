FROM alpine

# Basic tools for now
RUN apk add --update --no-cache bash ca-certificates curl jq git aws-cli openldap-clients build-base libffi-dev openssl-dev  python3 py3-pip

RUN python3 -m pip install --upgrade pip
## https://github.com/oracle/python-oracledb/issues/204
RUN python3 -m pip install -U "Cython<3.0.0"

RUN pip install git+https://github.com/ministryofjustice/hmpps-ldap-automation-cli.git@init-click

CMD ["ldap-automation"]