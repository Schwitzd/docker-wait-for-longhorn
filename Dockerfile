FROM alpine:latest

LABEL maintainer="Daniel Schwitzgebel <me@schwitzd.me>" \
      description="A minimal image that waits for all Longhorn volumes in the current Kubernetes namespace to be ready before proceeding."

RUN apk add --no-cache curl jq

COPY wait-for-longhorn.sh /usr/local/bin/wait-for-longhorn.sh
RUN chmod +x /usr/local/bin/wait-for-longhorn.sh

ENTRYPOINT ["/usr/local/bin/wait-for-longhorn.sh"]
