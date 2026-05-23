ARG BASE_IMAGE=docker.io/kalilinux/kali-bleeding-edge:latest
FROM ${BASE_IMAGE}

ARG BASE_IMAGE
ARG GITHUB_REPOSITORY=oneiros/ozbox
ARG OMP_VERSION=15.2.4
ARG SFW_VERSION=1.10.0
ARG FRIDA_TOOLS_VERSION=14.8.2
ARG TARGETARCH

LABEL org.opencontainers.image.title="ozbox"
LABEL org.opencontainers.image.description="Oneiros Zero Box: lightweight engagement container with SSH and research tooling"
LABEL org.opencontainers.image.source="https://github.com/${GITHUB_REPOSITORY}"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin
ENV PIP_NO_CACHE_DIR=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        adb \
        bash-completion \
        ca-certificates \
        curl \
        bind9-dnsutils \
        fd-find \
        file \
        fzf \
        git \
        iproute2 \
        iputils-ping \
        jq \
        less \
        lsof \
        nano \
        netcat-openbsd \
        nodejs \
        nmap \
        npm \
        openssh-server \
        pipx \
        procps \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
        socat \
        sudo \
        tmux \
        unzip \
        vim-tiny \
        wget \
        xz-utils \
        zip \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && useradd --create-home --shell /bin/bash --groups sudo john \
    && mkdir -p /run/sshd /work /opt/pipx /etc/ssh/sshd_config.d \
    && chown john:john /work \
    && printf 'john ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/john \
    && chmod 0440 /etc/sudoers.d/john \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -eux; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "${arch}" in \
        amd64|x86_64) omp_asset="omp-linux-x64"; omp_sha256="8015b08dafde4b62e78b8cfaf20f4c8f826d2f92778e717b151db9adc9435ce9" ;; \
        arm64|aarch64) omp_asset="omp-linux-arm64"; omp_sha256="bd4c3230aaa4664b39db31e6a00de02f213217e218ad900d6d0ffecf7562d817" ;; \
        *) printf 'unsupported OMP native architecture: %s\n' "${arch}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/can1357/oh-my-pi/releases/download/v${OMP_VERSION}/${omp_asset}" -o /usr/local/bin/omp; \
    printf '%s  /usr/local/bin/omp\n' "${omp_sha256}" | sha256sum -c -; \
    chmod 0755 /usr/local/bin/omp; \
    omp --version; \
    rm -rf /tmp/* /var/tmp/*

RUN set -eux; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "${arch}" in \
        amd64|x86_64) sfw_asset="sfw-free-linux-x86_64"; sfw_sha256="1ea16f15f1217bde66ac9c7d0262c7126b7bb1b2d60e14e8fa0982456139ae6e" ;; \
        arm64|aarch64) sfw_asset="sfw-free-linux-arm64"; sfw_sha256="d7e969c17e6d23ac1cb0dea81ff87ef9bca2d83570270d91aab14b2a7fb66ad4" ;; \
        *) printf 'unsupported sfw native architecture: %s\n' "${arch}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/SocketDev/sfw-free/releases/download/v${SFW_VERSION}/${sfw_asset}" -o /usr/local/bin/sfw; \
    printf '%s  /usr/local/bin/sfw\n' "${sfw_sha256}" | sha256sum -c -; \
    chmod 0755 /usr/local/bin/sfw; \
    sfw --help >/dev/null; \
    rm -rf /tmp/* /var/tmp/*

COPY constraints/pypi.txt /tmp/ozbox-pypi-constraints.txt

RUN set -eux; \
    pipx install --pip-args='--no-cache-dir --constraint /tmp/ozbox-pypi-constraints.txt' "frida-tools==${FRIDA_TOOLS_VERSION}"; \
    frida --version; \
    rm -f /tmp/ozbox-pypi-constraints.txt; \
    rm -rf /root/.cache /tmp/* /var/tmp/*

COPY container/sshd_config /etc/ssh/sshd_config
COPY container/profile.sh /etc/profile.d/ozbox.sh
COPY container/entrypoint.sh /usr/local/bin/ozbox-entrypoint

RUN chmod 0644 /etc/ssh/sshd_config /etc/profile.d/ozbox.sh \
    && chmod 0755 /usr/local/bin/ozbox-entrypoint

WORKDIR /work

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/ozbox-entrypoint"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
