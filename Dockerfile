FROM alpine:3

RUN apk add --no-cache ca-certificates bash coreutils lego openssl jq curl

ADD le-hpilo.sh /

VOLUME /.lego

ENTRYPOINT ["/le-hpilo.sh"]
