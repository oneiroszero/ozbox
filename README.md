# Ozbox

Oneiros Zero Box is a disposable research and engagement container. It keeps high-risk installs and day-to-day offensive tooling away from the host while staying easy to rebuild and throw away.

## Quick Start

Pull the published image:

```sh
docker run --rm -d --name ozbox -p 2222:22 -e OZBOX_PASSWORD=john \
  -v "$PWD:/work" ghcr.io/oneiroszero/ozbox:latest
ssh john@127.0.0.1 -p 2222
```

For key-based auth:

```sh
docker run --rm -d --name ozbox -p 2222:22 \
  -e "OZBOX_AUTHORIZED_KEY=$(cat ~/.ssh/id_ed25519.pub)" \
  -v "$PWD:/work" ghcr.io/oneiroszero/ozbox:latest
```

Docker Compose builds locally:

```sh
docker compose up --build
```

## Building

Images are built and published by GitHub Actions (`.github/workflows/build-image.yml`) on push to `main`, weekly, and on demand. `CACHE_BUST` re-resolves the floating tool versions on each run.

To build locally:

```sh
docker build --build-arg CACHE_BUST=$(date +%s) -t ozbox:dev .
```

The build fetches several tools from GitHub's API anonymously (~28 calls). That fits the 60/hour anonymous limit for a single build; if you rebuild rapidly and hit a rate limit, the tool-install step fails its count check — just wait for the limit to reset and rebuild.

## Tools

Kali-based; `john` is the primary user and everything below is on `PATH`.

**Reverse engineering & binary analysis**
- `radare2` — reverse-engineering framework
- `ghidra` — SRE suite at `/opt/ghidra` (plus ghidra-mcp, see below)
- `binwalk` — firmware extraction and analysis
- `ipsw` — iOS/macOS firmware research
- `frida` (frida-tools) — dynamic instrumentation
- `objection` — Frida-based mobile runtime exploration
- `hbc-decompiler` / `hbc-disassembler` / `hbc-file-parser` — React Native Hermes bytecode (hermes-dec)
- `apksigner` — APK signing & verification
- `plistutil` — Apple property-list conversion (libplist-utils)
- Python `lief` — parse/modify ELF, PE, Mach-O

**Recon & offensive (ProjectDiscovery)**
- `nuclei` — fast YAML-template vulnerability scanner
- `subfinder` — passive subdomain enumeration
- `httpx` — fast multi-purpose HTTP probing toolkit
- `naabu` — fast port scanner
- `dnsx` — fast multi-purpose DNS toolkit
- `katana` — crawling and spidering framework
- `tlsx` — TLS data grabber
- `cdncheck` — detect CDN/WAF/cloud tech behind an IP
- `asnmap` — map an org's network ranges via ASN
- `mapcidr` — CIDR/subnet range operations
- `uncover` — find exposed hosts via search engines (Shodan, Censys, …)
- `notify` — stream tool output to Slack/Discord/Telegram/etc.
- `proxify` — HTTP/HTTPS intercept proxy (capture, manipulate, replay)
- `shuffledns` — massdns wrapper for subdomain brute-force & resolution
- `interactsh-client` / `interactsh-server` — out-of-band (OAST) interaction client & server
- `chaos-client` — query the ProjectDiscovery Chaos subdomain dataset
- `alterx` — subdomain permutation/wordlist generator
- `urlfinder` — passive URL discovery
- `cloudlist` — enumerate assets across cloud providers
- `vulnx` — CLI for searching and exploring vulnerability (CVE) data
- `tldfinder` — discover TLDs/domains for an organization
- `tunnelx` — lightweight SOCKS5 ingress tunneling
- `aix` — CLI to interact with LLM APIs
- `simplehttpserver` — Go alternative to Python's SimpleHTTPServer

**Network**
- `nmap`, `socat`, `nc` (netcat), `dig` (bind9-dnsutils), `adb`

**Other**
- `omp` — oh-my-pi, an AI agent
- shell/dev: `git`, `jq`, `rg` (ripgrep), `fd`, `fzf`, `tmux`, `vim`, `nano`, `node`/`npm`, `python3`/`pipx`

## Ghidra MCP

Ghidra 12.1 and the [bethington/ghidra-mcp](https://github.com/bethington/ghidra-mcp) headless server are installed and ready to use, but **not started automatically**. Two launchers are on `PATH`:

- `ghidra-mcp-server` — the headless Ghidra MCP HTTP server. Binds `127.0.0.1:8089` by default; override with `GHIDRA_MCP_PORT`, `GHIDRA_MCP_BIND_ADDRESS`, or `JAVA_OPTS`.
- `ghidra-mcp-bridge` — the Python MCP bridge. Connects to the server at `GHIDRA_MCP_URL` (default `http://127.0.0.1:8089/`).

Start the server, then run the bridge (or wire it up as your MCP client's server command):

```sh
ghidra-mcp-server &   # headless HTTP server on :8089
ghidra-mcp-bridge     # MCP bridge talking to the server
```

Ghidra itself lives at `/opt/ghidra` (e.g. `/opt/ghidra/support/analyzeHeadless`).

## Notes

External tools float to their latest versions on each rebuild; Ghidra is pinned to the version the MCP plugin targets. The package set is expected to evolve as the toolkit grows.
