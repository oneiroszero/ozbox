ARG BASE_IMAGE=docker.io/kalilinux/kali-bleeding-edge:latest

# ===== ghidra-mcp headless server builder =====
# Ghidra's version is coupled to the plugin's pom.xml <ghidra.version>; bump
# GHIDRA_VERSION + GHIDRA_DATE together with GHIDRA_MCP_REF when upstream retargets.
FROM eclipse-temurin:21-jdk AS ghidra-mcp-builder
ARG GHIDRA_VERSION=12.1
ARG GHIDRA_DATE=20260513
ARG GHIDRA_MCP_REF=v5.12.0
RUN apt-get update \
    && apt-get install -y --no-install-recommends wget unzip maven git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt
RUN wget -q "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_DATE}.zip" -O ghidra.zip \
    && unzip -q ghidra.zip \
    && rm ghidra.zip \
    && mv ghidra_* ghidra
ENV GHIDRA_HOME=/opt/ghidra
RUN set -eux; \
    for entry in \
        Framework/Generic:Generic \
        Framework/SoftwareModeling:SoftwareModeling \
        Framework/Project:Project \
        Framework/Docking:Docking \
        Framework/Utility:Utility \
        Framework/Gui:Gui \
        Framework/FileSystem:FileSystem \
        Framework/Help:Help \
        Features/Base:Base \
        Features/Decompiler:Decompiler \
        Framework/DB:DB \
        Framework/Emulation:Emulation \
        Debug/Debugger-api:Debugger-api \
        Debug/Framework-TraceModeling:Framework-TraceModeling \
        Debug/Debugger-rmi-trace:Debugger-rmi-trace \
    ; do \
        dir="${entry%%:*}"; art="${entry##*:}"; \
        mvn -q install:install-file \
            -Dfile="/opt/ghidra/Ghidra/${dir}/lib/${art}.jar" \
            -DgroupId=ghidra -DartifactId="${art}" -Dversion="${GHIDRA_VERSION}" -Dpackaging=jar; \
    done
RUN git clone --depth 1 --branch "${GHIDRA_MCP_REF}" https://github.com/bethington/ghidra-mcp /build
WORKDIR /build
RUN mvn clean package -P headless -DskipTests -q

# ===== ozbox base image =====
FROM ${BASE_IMAGE} AS base

ARG BASE_IMAGE
ARG GITHUB_REPOSITORY=oneiros/ozbox
ARG CACHE_BUST=manual

LABEL org.opencontainers.image.title="ozbox"
LABEL org.opencontainers.image.description="Oneiros Zero Box: lightweight Kali research container with SSH"
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
        bash-completion \
        bind9-dnsutils \
        curl \
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
        npm \
        openssh-server \
        pipx \
        procps \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
        seclists \
        socat \
        sudo \
        tmux \
        unzip \
        vim-tiny \
        wget \
        wordlists \
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
    omp --version; \
    rm -rf /root/.omp /tmp/* /var/tmp/*

COPY container/sshd_config /etc/ssh/sshd_config
COPY container/profile.sh /etc/profile.d/ozbox.sh
COPY container/entrypoint.sh /usr/local/bin/ozbox-entrypoint

RUN chmod 0644 /etc/ssh/sshd_config /etc/profile.d/ozbox.sh \
    && chmod 0755 /usr/local/bin/ozbox-entrypoint

WORKDIR /work

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/ozbox-entrypoint"]
CMD ["/usr/sbin/sshd", "-D", "-e"]

# ===== web/recon image =====
FROM base AS web

# Install pdtm via `go install`, then purge Go BEFORE `pdtm -ia` so a rate-limited
# binary fetch can't fall back to a source build (which previously ran the disk
# out of space). pdtm downloads the tool binaries directly; without Go a throttled
# fetch just skips a tool rather than compiling it.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends feroxbuster ffuf golang-go libpcap0.8 nmap; \
    GOBIN=/usr/local/bin go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest; \
    apt-get purge -y golang-go; \
    apt-get autoremove --purge -y; \
    pdtm -version >/dev/null; \
    pdtm -ia -duc -nc; \
    installed="$(find /root/.pdtm/go/bin -maxdepth 1 -type f 2>/dev/null | wc -l)"; \
    test "${installed}" -ge 20 || { printf 'pdtm installed only %s tools, expected >=20 (GitHub anonymous rate limit? retry later)\n' "${installed}" >&2; exit 1; }; \
    for f in /root/.pdtm/go/bin/*; do install -m 0755 "$f" /usr/local/bin/; done; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /root/go /root/.cache /root/.config/go /root/.config/pdtm /root/.pdtm /tmp/* /var/tmp/*

# ===== reverse engineering/mobile image =====
FROM base AS re

ARG TARGETARCH

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        adb \
        apksigner \
        binwalk \
        libplist-utils \
        openjdk-21-jre-headless \
        python3-lief \
        radare2; \
    apt-get autoremove --purge -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /var/log/* /tmp/* /var/tmp/* \
              /usr/share/doc/* /usr/share/man/* /usr/share/locale/* /usr/share/info/*

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

# ghidra-mcp: Ghidra + headless plugin jar + Python MCP bridge (NOT auto-started).
ENV GHIDRA_HOME=/opt/ghidra
COPY --from=ghidra-mcp-builder /opt/ghidra /opt/ghidra
COPY --from=ghidra-mcp-builder /build/target/GhidraMCP-*.jar /opt/ghidra-mcp/GhidraMCP.jar
COPY --from=ghidra-mcp-builder /build/bridge_mcp_ghidra.py /opt/ghidra-mcp/bridge_mcp_ghidra.py
COPY container/ghidra-mcp-server /usr/local/bin/ghidra-mcp-server
COPY container/ghidra-mcp-bridge /usr/local/bin/ghidra-mcp-bridge

RUN set -eux; \
    python3 -m venv /opt/ghidra-mcp/venv; \
    /opt/ghidra-mcp/venv/bin/pip install --no-cache-dir mcp requests; \
    chmod 0755 /usr/local/bin/ghidra-mcp-server /usr/local/bin/ghidra-mcp-bridge; \
    java -version; \
    test -f /opt/ghidra-mcp/GhidraMCP.jar; \
    test -x /opt/ghidra/support/analyzeHeadless; \
    /opt/ghidra-mcp/venv/bin/python -c "import mcp, requests"; \
    find /opt/ghidra-mcp/venv -type d -name __pycache__ -prune -exec rm -rf {} +; \
    rm -rf /root/.cache /tmp/* /var/tmp/*

# ===== full image =====
FROM web AS full

ARG TARGETARCH

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        adb \
        apksigner \
        binwalk \
        libplist-utils \
        openjdk-21-jre-headless \
        python3-lief \
        radare2; \
    apt-get autoremove --purge -y; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /var/log/* /tmp/* /var/tmp/* \
              /usr/share/doc/* /usr/share/man/* /usr/share/locale/* /usr/share/info/*

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

# ghidra-mcp: Ghidra + headless plugin jar + Python MCP bridge (NOT auto-started).
ENV GHIDRA_HOME=/opt/ghidra
COPY --from=ghidra-mcp-builder /opt/ghidra /opt/ghidra
COPY --from=ghidra-mcp-builder /build/target/GhidraMCP-*.jar /opt/ghidra-mcp/GhidraMCP.jar
COPY --from=ghidra-mcp-builder /build/bridge_mcp_ghidra.py /opt/ghidra-mcp/bridge_mcp_ghidra.py
COPY container/ghidra-mcp-server /usr/local/bin/ghidra-mcp-server
COPY container/ghidra-mcp-bridge /usr/local/bin/ghidra-mcp-bridge

RUN set -eux; \
    python3 -m venv /opt/ghidra-mcp/venv; \
    /opt/ghidra-mcp/venv/bin/pip install --no-cache-dir mcp requests; \
    chmod 0755 /usr/local/bin/ghidra-mcp-server /usr/local/bin/ghidra-mcp-bridge; \
    java -version; \
    test -f /opt/ghidra-mcp/GhidraMCP.jar; \
    test -x /opt/ghidra/support/analyzeHeadless; \
    /opt/ghidra-mcp/venv/bin/python -c "import mcp, requests"; \
    find /opt/ghidra-mcp/venv -type d -name __pycache__ -prune -exec rm -rf {} +; \
    rm -rf /root/.cache /tmp/* /var/tmp/*
