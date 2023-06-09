FROM python:3.9-alpine3.14

COPY test.py /test.py

RUN pip install ldap3

ENTRYPOINT [ "python3", "/test.py" ]
