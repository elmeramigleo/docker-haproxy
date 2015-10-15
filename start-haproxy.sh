#!/bin/bash

set -e

echo "=> Configuring Haproxy"

cp -v /etc/haproxy/haproxy.cfg.template /etc/haproxy/haproxy.cfg
sed -i -e "s/<--MODE-->/${MODE}/g" /etc/haproxy/haproxy.cfg

# check if we have server certificate
if [ "${CERTIFICATE}" != "" ]; then

    # check if we have server ca
    if [ "${CA}" != "" ]; then
        echo "    bind *:${LISTENPORT} ssl crt /usr/local/etc/haproxy/certs/${CERTIFICATE} /usr/local/etc/haproxy/certs/${CA} verify ${VERIFY}" >> /etc/haproxy/haproxy.cfg
    else
        echo "    bind *:${LISTENPORT} ssl crt /usr/local/etc/haproxy/certs/${CERTIFICATE}" >> /etc/haproxy/haproxy.cfg
    fi

else
    echo "    bind *:${LISTENPORT}" >> /etc/haproxy/haproxy.cfg
fi

# check if we have default backend
if [ "${DEFAULT}" != "" ]; then

    echo "    default_backend ${DEFAULT}" >> /etc/haproxy/haproxy.cfg

else

    # generate acl rules
     for BACKEND in $( env |grep BACKEND_ |sort |awk 'match($0, /BACKEND_[0-9]+/) { print substr( $0, RSTART, RLENGTH )}' |uniq )
     do
        echo "    acl is_${BACKEND} hdr_dom(${HEADERNAME}) -i ${BACKEND}" >> /etc/haproxy/haproxy.cfg
        echo "    use_backend ${BACKEND} if is_${BACKEND}" >> /etc/haproxy/haproxy.cfg
        echo "" >> /etc/haproxy/haproxy.cfg
    done

fi

for BACKEND in $( env |grep BACKEND_ |sort |awk 'match($0, /BACKEND_[0-9]+/) { print substr( $0, RSTART, RLENGTH )}' |uniq )
do
  echo "backend ${BACKEND}" >> /etc/haproxy/haproxy.cfg
  for ELEMENT in $( env |grep ${BACKEND} |sort )
  do

    case "$ELEMENT" in
      *HEADERVALUE*)
        HEADERVALUE=$( echo $ELEMENT |sed 's/BACKEND_.*=//' )
        ;;
      *ADDRESS*)
        ADDRESS=$( echo $ELEMENT |sed 's/BACKEND_.*=//' )
        ;;
      *PORT*)
        PORT=$( echo $ELEMENT |sed 's/BACKEND_.*=//' )
        ;;
      *CERTIFICATE*)
        CERTIFICATE=$( echo $ELEMENT |sed 's/BACKEND_.*=//' )
        ;;
    esac

  done

    # check if cert was provided
    CERT_PATH="/usr/local/etc/haproxy/certs/${CERTIFICATE}"
    if [ "$CERTIFICATE" != "" ]; then
        PARAMS="ssl crt ${CERT_PATH} verify none"
    else
        PARAMS="verify none"
    fi
    echo "    server ${BACKEND} ${ADDRESS}:${PORT} ${PARAMS}" >> /etc/haproxy/haproxy.cfg

done

# should we enable logging
if [ "$LOGGING" == "enabled" ]; then
    (rsyslogd -n &)
fi

exec haproxy -db -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid
