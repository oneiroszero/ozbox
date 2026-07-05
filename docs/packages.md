# Package Inventory

This file tracks the packages and tools installed directly by `Dockerfile`. It intentionally separates runtime contents from build-only dependencies.

## Image Variants

| Variant | Docker target | Published tags | Includes |
| --- | --- | --- | --- |
| Base | `base` | `latest`, `base`, `vX.Y.Z`, `vX.Y.Z-base` | Kali SSH/dev baseline |
| Web | `web` | `web`, `vX.Y.Z-web` | Base plus web engagement and recon tools |
| RE | `re` | `re`, `vX.Y.Z-re` | Base plus reverse engineering and mobile tools |
| Full | `full` | `full`, `vX.Y.Z-full` | Web plus reverse engineering and mobile tools |

## Runtime APT Packages

| Package | Variants | Purpose |
| --- | --- | --- |
| `ca-certificates` | base, web, re, full | TLS trust store |
| `bash-completion` | base, web, re, full | Shell completion support |
| `bind9-dnsutils` | base, web, re, full | DNS tools such as `dig` |
| `curl` | base, web, re, full | HTTP client and installer fetches |
| `fd-find` | base, web, re, full | File search; symlinked as `fd` |
| `file` | base, web, re, full | File type identification |
| `fzf` | base, web, re, full | Fuzzy finder |
| `git` | base, web, re, full | Version control |
| `iproute2` | base, web, re, full | Network interface and route tools |
| `iputils-ping` | base, web, re, full | `ping` |
| `jq` | base, web, re, full | JSON processing |
| `less` | base, web, re, full | Pager |
| `lsof` | base, web, re, full | Open-file and socket inspection |
| `nano` | base, web, re, full | Editor |
| `netcat-openbsd` | base, web, re, full | `nc` |
| `nodejs` | base, web, re, full | Node.js runtime |
| `npm` | base, web, re, full | Node package manager |
| `openssh-server` | base, web, re, full | SSH daemon |
| `pipx` | base, web, re, full | Isolated Python CLI installer |
| `procps` | base, web, re, full | Process tools such as `ps` |
| `python3` | base, web, re, full | Python runtime |
| `python3-pip` | base, web, re, full | Python package installer |
| `python3-venv` | base, web, re, full | Python virtual environment support |
| `ripgrep` | base, web, re, full | `rg` search |
| `seclists` | base, web, re, full | Security testing wordlists under `/usr/share/seclists` |
| `socat` | base, web, re, full | Socket relay tool |
| `sudo` | base, web, re, full | Passwordless sudo for `john` |
| `tmux` | base, web, re, full | Terminal multiplexer |
| `unzip` | base, web, re, full | ZIP extraction |
| `vim-tiny` | base, web, re, full | Editor |
| `wget` | base, web, re, full | HTTP fetcher |
| `wordlists` | base, web, re, full | Kali wordlist collection under `/usr/share/wordlists` |
| `xz-utils` | base, web, re, full | XZ compression utilities |
| `zip` | base, web, re, full | ZIP creation |
| `feroxbuster` | web, full | Recursive content discovery |
| `ffuf` | web, full | Web fuzzing |
| `libpcap0.8` | web, full | Packet capture runtime library |
| `nmap` | web, full | Network scanning |
| `adb` | re, full | Android Debug Bridge |
| `apksigner` | re, full | APK signing and verification |
| `apktool` | re, full | Android APK reverse engineering |
| `binwalk` | re, full | Firmware extraction and analysis |
| `gdb` | re, full | GNU debugger |
| `jadx` | re, full | Dex to Java decompiler |
| `libimage-exiftool-perl` | re, full | Provides `exiftool` |
| `libplist-utils` | re, full | Apple property-list tools, including `plistutil` |
| `ltrace` | re, full | Library call tracing |
| `openjdk-21-jre-headless` | re, full | Java runtime for Ghidra |
| `python3-lief` | re, full | Python LIEF bindings |
| `radare2` | re, full | Reverse-engineering framework |
| `strace` | re, full | System call tracing |
| `xxd` | re, full | Hex dump utility |

## Runtime Tools From Other Sources

| Tool or package | Variants | Source | Notes |
| --- | --- | --- | --- |
| `omp` | base, web, re, full | `https://omp.sh/install` | Installed as a binary in `/usr/local/bin` |
| `pdtm` | web, full | `go install github.com/projectdiscovery/pdtm/cmd/pdtm@latest` | Used to install ProjectDiscovery tools and remains on `PATH` |
| `sqlmap` | web, full | Shallow clone of `sqlmapproject/sqlmap` | Installed at `/opt/sqlmap` with a `/usr/local/bin/sqlmap` wrapper |
| `arjun` | web, full | `pipx` from `s0md3v/Arjun` | HTTP parameter discovery |
| `gef` | re, full | Shallow clone of `hugsy/gef` | Installed at `/opt/gef`; sourced from `/etc/gdb/gdbinit` |
| `ipsw` | re, full | Latest GitHub release from `blacktop/ipsw` | Architecture-specific Linux tarball |
| `frida-tools` | re, full | `pipx` | Provides `frida` and related CLIs |
| `objection` | re, full | `pipx` | Mobile runtime exploration |
| `hermes-dec` | re, full | `pipx` | Provides Hermes bytecode tools |
| `ghidra` | re, full | NSA Ghidra release archive | Installed at `/opt/ghidra` |
| `GhidraMCP.jar` | re, full | `bethington/ghidra-mcp` build output | Headless Ghidra MCP server plugin |
| `bridge_mcp_ghidra.py` | re, full | `bethington/ghidra-mcp` build output | Python MCP bridge |
| `mcp` | re, full | `pip` inside `/opt/ghidra-mcp/venv` | Python dependency for the bridge |
| `requests` | re, full | `pip` inside `/opt/ghidra-mcp/venv` | Python dependency for the bridge |

## ProjectDiscovery Tools

Installed by `pdtm -ia -duc -nc` in the `web` and `full` images.

| Tool | Variants |
| --- | --- |
| `aix` | web, full |
| `alterx` | web, full |
| `asnmap` | web, full |
| `cdncheck` | web, full |
| `chaos-client` | web, full |
| `cloudlist` | web, full |
| `dnsx` | web, full |
| `httpx` | web, full |
| `interactsh-client` | web, full |
| `interactsh-server` | web, full |
| `katana` | web, full |
| `mapcidr` | web, full |
| `naabu` | web, full |
| `notify` | web, full |
| `nuclei` | web, full |
| `proxify` | web, full |
| `shuffledns` | web, full |
| `simplehttpserver` | web, full |
| `subfinder` | web, full |
| `tldfinder` | web, full |
| `tlsx` | web, full |
| `tunnelx` | web, full |
| `uncover` | web, full |
| `urlfinder` | web, full |
| `vulnx` | web, full |

## Build-Only Dependencies

| Dependency | Used in | Runtime image? | Notes |
| --- | --- | --- | --- |
| `wget` | `ghidra-mcp-builder` | No, except base has its own runtime `wget` package | Fetches the Ghidra release archive in the builder stage |
| `unzip` | `ghidra-mcp-builder` | No, except base has its own runtime `unzip` package | Extracts Ghidra in the builder stage |
| `maven` | `ghidra-mcp-builder` | No | Builds the Ghidra MCP plugin |
| `git` | `ghidra-mcp-builder` | No, except base has its own runtime `git` package | Clones `bethington/ghidra-mcp` |
| `ca-certificates` | `ghidra-mcp-builder` | No, except base has its own runtime `ca-certificates` package | TLS trust for downloads |
| `golang-go` | `web`, `full` build steps | No | Builds `pdtm`, then is purged before the final layer completes |
