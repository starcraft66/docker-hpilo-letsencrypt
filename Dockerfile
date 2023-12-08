FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    coreutils \
    lego \
    openssl \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

ADD le-hpilo.sh /

VOLUME /.lego

WORKDIR /

ENTRYPOINT ["/le-hpilo.sh"]
