FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    coreutils \
    openssl \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl https://github.com/go-acme/lego/releases/download/v4.15.0/lego_v4.15.0_linux_amd64.tar.gz -L -o lego.tar.gz \
    && tar xzf lego.tar.gz \
    && mv lego /usr/local/bin \
    && rm lego.tar.gz

ADD le-hpilo.sh /

VOLUME /.lego

WORKDIR /

ENTRYPOINT ["/le-hpilo.sh"]
