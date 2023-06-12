FROM python:3.9-alpine3.14

COPY test.py /test.py

RUN pip install ldap3

ENTRYPOINT [ "python3", "/test.py" ]

# FROM alpine:3.17

# RUN apk add --update --no-cache openldap-clients bash

# COPY test.sh /test.sh

# RUN chmod a+x /test.sh

# ENTRYPOINT [ "/test.sh" ]