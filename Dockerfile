FROM alpine:3.4
MAINTAINER Joeri van Dooren <ure@moreorless.be>

ADD scripts/sync.sh /scripts/sync.sh

RUN apk upgrade && \
 apk add --update bash ca-certificates python py-pip && \
 pip install python-dateutil python-magic s3cmd && \
 chmod -R a+rx /scripts && \
 rm -f /var/cache/apk/*

WORKDIR /scripts

ENTRYPOINT ["/scripts/sync.sh"]

# Set labels used in OpenShift to describe the builder images
LABEL io.k8s.description="S3 Backup" \
      io.k8s.display-name="S3 Bacup" \
      io.openshift.expose-services="" \
      io.openshift.tags="builder,asterisk" \
      io.openshift.min-memory="1Gi" \
      io.openshift.min-cpu="1" \
      io.openshift.non-scalable="false"
