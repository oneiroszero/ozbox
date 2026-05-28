ARG BASE_IMAGE=docker.io/kalilinux/kali-bleeding-edge:latest
FROM ${BASE_IMAGE}

ARG BASE_IMAGE
ARG GITHUB_REPOSITORY=oneiros/ozbox
ARG CACHE_BUST=manual
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

RUN echo "cache-bust=${CACHE_BUST}" >/dev/null \
    && sed -i 's|http://http\.kali\.org/kali/|http://kali.download/kali/|g' /etc/apt/sources.list.d/kali.sources \
    && printf 'Acquire::Retries "5";\nAcquire::Retries::Delay "true";\n' > /etc/apt/apt.conf.d/80-ozbox-retries \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && sed -i 's|http://kali.download/kali/|https://kali.download/kali/|g' /etc/apt/sources.list.d/kali.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        adb \
        apksigner \
        bash-completion \
        binwalk \
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
        libplist-utils \
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
        python3-lief \
        python3-pip \
        python3-venv \
        radare2 \
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
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* /var/log/* /tmp/* /var/tmp/* \
              /usr/share/doc/* /usr/share/man/* /usr/share/locale/* /usr/share/info/*

RUN set -eux; \
    curl -fsSL https://omp.sh/install -o /tmp/omp-install.sh; \
    PI_INSTALL_DIR=/usr/local/bin sh /tmp/omp-install.sh --binary; \
    rm -f /tmp/omp-install.sh; \
    omp --version; \
    rm -rf /root/.omp /tmp/* /var/tmp/*

RUN set -eux; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "${arch}" in \
        amd64|x86_64) sfw_asset="sfw-free-linux-x86_64" ;; \
        arm64|aarch64) sfw_asset="sfw-free-linux-arm64" ;; \
        *) printf 'unsupported sfw native architecture: %s\n' "${arch}" >&2; exit 1 ;; \
    esac; \
    sfw_tag="$(curl -fsSL https://api.github.com/repos/SocketDev/sfw-free/releases/latest | jq -r .tag_name)"; \
    curl -fsSL "https://github.com/SocketDev/sfw-free/releases/download/${sfw_tag}/${sfw_asset}" -o /usr/local/bin/sfw; \
    chmod 0755 /usr/local/bin/sfw; \
    sfw --help >/dev/null; \
    rm -rf /tmp/* /var/tmp/*

RUN set -eux; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "${arch}" in \
        amd64|x86_64) ipsw_asset_arch="x86_64" ;; \
        arm64|aarch64) ipsw_asset_arch="arm64" ;; \
        *) printf 'unsupported ipsw native architecture: %s\n' "${arch}" >&2; exit 1 ;; \
    esac; \
    ipsw_tag="$(curl -fsSL https://api.github.com/repos/blacktop/ipsw/releases/latest | jq -r .tag_name)"; \
    ipsw_ver="${ipsw_tag#v}"; \
    mkdir -p /tmp/ipsw-extract; \
    curl -fsSL "https://github.com/blacktop/ipsw/releases/download/${ipsw_tag}/ipsw_${ipsw_ver}_linux_${ipsw_asset_arch}.tar.gz" -o /tmp/ipsw.tar.gz; \
    tar -xzf /tmp/ipsw.tar.gz -C /tmp/ipsw-extract; \
    install -m 0755 "$(find /tmp/ipsw-extract -type f -name ipsw -perm -u+x | head -n1)" /usr/local/bin/ipsw; \
    ipsw version >/dev/null; \
    rm -rf /tmp/* /var/tmp/*

RUN set -eux; \
    pipx install --pip-args='--no-cache-dir' frida-tools; \
    pipx install --pip-args='--no-cache-dir' objection; \
    pipx install --pip-args='--no-cache-dir' hermes-dec; \
    frida --version; \
    objection version >/dev/null; \
    hbc-disassembler --help >/dev/null; \
    find /opt/pipx -type d -name __pycache__ -prune -exec rm -rf {} +; \
    rm -rf /root/.cache /root/.objection /root/.local /tmp/* /var/tmp/*

COPY container/sshd_config /etc/ssh/sshd_config
COPY container/profile.sh /etc/profile.d/ozbox.sh
COPY container/entrypoint.sh /usr/local/bin/ozbox-entrypoint

RUN chmod 0644 /etc/ssh/sshd_config /etc/profile.d/ozbox.sh \
    && chmod 0755 /usr/local/bin/ozbox-entrypoint

WORKDIR /work

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/ozbox-entrypoint"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
