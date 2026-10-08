ARG FEDORA_VERSION=45

FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_VERSION}

COPY systemd/bootc-fetch.service /usr/lib/systemd/system/bootc-fetch.service
COPY systemd/bootc-fetch.timer /usr/lib/systemd/system/bootc-fetch.timer
COPY scripts/build.sh /tmp/build.sh
RUN bash /tmp/build.sh && rm /tmp/build.sh

RUN systemctl enable keyd && \
    systemctl enable bootc-fetch.timer && \
    systemctl enable docker.socket && \
    bootc container lint
