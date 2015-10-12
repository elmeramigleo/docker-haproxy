FROM alpine:3.2

MAINTAINER Lukasz Czarski <l.czarski@oberthur.com>

ENV HAPROXY_VERSION=1.5.14-r0

ADD haproxy.cfg /etc/haproxy/haproxy.cfg.template
ADD start-haproxy.sh /bin/start-haproxy.sh
ADD haproxy.rsyslog /etc/rsyslog.conf

# Prepare image
RUN chmod +x /bin/start-haproxy.sh \
    && apk add haproxy=${HAPROXY_VERSION} bash rsyslog --update-cache \
    && ln -sf /dev/stdout /var/log/haproxy.log

ENTRYPOINT ["/bin/start-haproxy.sh"]
