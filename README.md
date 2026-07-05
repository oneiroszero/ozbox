# Ozbox

Oneiros Zero Box is a disposable Kali research and engagement container. It keeps high-risk installs and day-to-day offensive tooling away from the host while staying easy to rebuild and throw away.

Inspired by [Taka](https://github.com/0xf61/taka), Ozbox keeps the same rebuildable local research-box spirit while focusing on a Kali/SSH workflow and opt-in tool variants.

## Quick Start

`latest` is the base image.

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

Use a heavier variant by changing the tag:

```sh
docker run --rm -d --name ozbox-web -p 2222:22 -e OZBOX_PASSWORD=john \
  -v "$PWD:/work" ghcr.io/oneiroszero/ozbox:web
```

Docker Compose builds the base image locally:

```sh
docker compose up --build
```

## Published Tags

Images are built and published publicly to GHCR by GitHub Actions (`.github/workflows/build-image.yml`) on push to `main`, version tags, weekly, and on demand.

| Tag | Contents | Size profile |
| --- | --- | --- |
| `latest`, `base` | Kali SSH/dev baseline | Smallest |
| `web` | Base plus web engagement and recon tooling | Medium |
| `re` | Base plus reverse engineering and mobile tooling | Large |
| `full` | Web plus reverse engineering and mobile tooling | Largest |

Version tags follow the same policy: `vX.Y.Z` points to the base image, and variant tags are published as `vX.Y.Z-base`, `vX.Y.Z-web`, `vX.Y.Z-re`, and `vX.Y.Z-full`.

## Building

Build a specific target locally:

```sh
docker build --target base --build-arg CACHE_BUST=$(date +%s) -t ozbox:base .
docker build --target web --build-arg CACHE_BUST=$(date +%s) -t ozbox:web .
docker build --target re --build-arg CACHE_BUST=$(date +%s) -t ozbox:re .
docker build --target full --build-arg CACHE_BUST=$(date +%s) -t ozbox:full .
```

`CACHE_BUST` re-resolves floating tool versions. The `web` and `full` targets fetch ProjectDiscovery tools from GitHub via `pdtm`; if you rebuild rapidly and hit GitHub's anonymous rate limit, the tool-install step fails its count check. Wait for the limit to reset and rebuild.

## Tools

Kali-based; `john` is the primary user and tools are installed on `PATH` unless noted otherwise.

For the direct package and tool inventory by variant, see [docs/packages.md](docs/packages.md).

**Base (`latest`, `base`)**

- SSH runtime with password or authorized-key auth
- shell/dev: `git`, `jq`, `rg` (ripgrep), `fd`, `fzf`, `tmux`, `vim`, `nano`
- languages: `node`/`npm`, `python3`/`pipx`
- network basics: `curl`, `dig`, `nc` (netcat), `socat`, `ping`, `ip`
- wordlists: `seclists`, Kali `wordlists`
- `omp` - oh-my-pi, an AI agent

**Web (`web`, `full`)**

- `feroxbuster`, `ffuf`, `nmap`
- ProjectDiscovery tooling:
  `nuclei`, `subfinder`, `httpx`, `naabu`, `dnsx`, `katana`, `tlsx`,
  `cdncheck`, `asnmap`, `mapcidr`, `uncover`, `notify`, `proxify`,
  `shuffledns`, `interactsh-client`, `interactsh-server`, `chaos-client`,
  `alterx`, `urlfinder`, `cloudlist`, `vulnx`, `tldfinder`, `tunnelx`,
  `aix`, `simplehttpserver`

**Reverse engineering and mobile (`re`, `full`)**

- `radare2` - reverse-engineering framework
- `ghidra` - SRE suite at `/opt/ghidra` plus ghidra-mcp
- `binwalk` - firmware extraction and analysis
- `ipsw` - iOS/macOS firmware research
- `frida` (frida-tools) - dynamic instrumentation
- `objection` - Frida-based mobile runtime exploration
- `hbc-decompiler`, `hbc-disassembler`, `hbc-file-parser` - React Native Hermes bytecode
- `adb`, `apksigner`, `plistutil`
- Python `lief` - parse/modify ELF, PE, Mach-O

## Ghidra MCP

Ghidra 12.1 and the [bethington/ghidra-mcp](https://github.com/bethington/ghidra-mcp) headless server are installed in the `re` and `full` images, but **not started automatically**. Two launchers are on `PATH`:

- `ghidra-mcp-server` - the headless Ghidra MCP HTTP server. Binds `127.0.0.1:8089` by default; override with `GHIDRA_MCP_PORT`, `GHIDRA_MCP_BIND_ADDRESS`, or `JAVA_OPTS`.
- `ghidra-mcp-bridge` - the Python MCP bridge. Connects to the server at `GHIDRA_MCP_URL` (default `http://127.0.0.1:8089/`).

Start the server, then run the bridge (or wire it up as your MCP client's server command):

```sh
ghidra-mcp-server &   # headless HTTP server on :8089
ghidra-mcp-bridge     # MCP bridge talking to the server
```

Ghidra itself lives at `/opt/ghidra` (e.g. `/opt/ghidra/support/analyzeHeadless`).

## Notes

External tools float to their latest versions on each rebuild; Ghidra is pinned to the version the MCP plugin targets. The package set is expected to evolve as the toolkit grows.
