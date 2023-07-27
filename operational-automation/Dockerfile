FROM alpine

# Basic tools for now
RUN apk add --update --no-cache bash ca-certificates curl jq git aws-cli openldap-clients 

COPY scripts /scripts

RUN chmod +x /scripts/*.sh

CMD ["/bin/bash"]