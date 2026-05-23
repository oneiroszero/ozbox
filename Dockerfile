ARG BASE_IMAGE=docker.io/kalilinux/kali-bleeding-edge:latest
FROM ${BASE_IMAGE}

ARG BASE_IMAGE
ARG GITHUB_REPOSITORY=oneiros/ozbox
ARG OMP_VERSION=latest
ARG SFW_VERSION=latest
ARG FRIDA_TOOLS_VERSION=latest
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
    && apt-get update \
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
    curl -fsSL https://omp.sh/install -o /tmp/omp-install.sh; \
    if [ "${OMP_VERSION}" = "latest" ]; then \
        PI_INSTALL_DIR=/usr/local/bin sh /tmp/omp-install.sh --binary; \
    else \
        PI_INSTALL_DIR=/usr/local/bin sh /tmp/omp-install.sh --binary --ref "v${OMP_VERSION#v}"; \
    fi; \
    rm -f /tmp/omp-install.sh; \
    omp --version; \
    rm -rf /tmp/* /var/tmp/*

RUN set -eux; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "${arch}" in \
        amd64|x86_64) sfw_asset="sfw-free-linux-x86_64" ;; \
        arm64|aarch64) sfw_asset="sfw-free-linux-arm64" ;; \
        *) printf 'unsupported sfw native architecture: %s\n' "${arch}" >&2; exit 1 ;; \
    esac; \
    if [ "${SFW_VERSION}" = "latest" ]; then \
        sfw_tag="$(curl -fsSL https://api.github.com/repos/SocketDev/sfw-free/releases/latest | jq -r .tag_name)"; \
    else \
        sfw_tag="v${SFW_VERSION#v}"; \
    fi; \
    curl -fsSL "https://github.com/SocketDev/sfw-free/releases/download/${sfw_tag}/${sfw_asset}" -o /usr/local/bin/sfw; \
    chmod 0755 /usr/local/bin/sfw; \
    sfw --help >/dev/null; \
    rm -rf /tmp/* /var/tmp/*

RUN set -eux; \
    if [ "${FRIDA_TOOLS_VERSION}" = "latest" ]; then \
        frida_package="frida-tools"; \
    else \
        frida_package="frida-tools==${FRIDA_TOOLS_VERSION}"; \
    fi; \
    pipx install --pip-args='--no-cache-dir' "${frida_package}"; \
    frida --version; \
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
