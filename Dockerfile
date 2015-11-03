FROM oberthur/docker-ubuntu:14.04.3

MAINTAINER Dawid Malinowski <d.malinowski@oberthur.com>

ENV HAPROXY_VERSION=1.6.1

ADD haproxy.cfg /etc/haproxy/haproxy.cfg.template
ADD start-haproxy.sh /bin/start-haproxy.sh
ADD start-simple.sh /bin/start-simple.sh

# Prepare image
RUN chmod +x /bin/start-haproxy.sh \
    && add-apt-repository ppa:vbernat/haproxy-1.6 \
    && apt-get update \
    && apt-get install rsyslog haproxy=${HAPROXY_VERSION}* \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && ln -sf /dev/stdout /var/log/haproxy.log

ADD haproxy.rsyslog /etc/rsyslog.conf

ENTRYPOINT ["/bin/start-haproxy.sh"]
