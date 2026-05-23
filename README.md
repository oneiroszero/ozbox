# Ozbox

Oneiros Zero Box is a disposable research and engagement container. It keeps high-risk installs and day-to-day offensive tooling away from the host while staying easy to rebuild and throw away.

## Quick Start

```sh
docker build -t ozbox:dev .
docker run --rm -d --name ozbox -p 2222:22 -e OZBOX_PASSWORD=john -v "$PWD:/work" ozbox:dev
ssh john@127.0.0.1 -p 2222
```

For key-based auth:

```sh
docker run --rm -d --name ozbox -p 2222:22 \
  -e "OZBOX_AUTHORIZED_KEY=$(cat ~/.ssh/id_ed25519.pub)" \
  -v "$PWD:/work" ozbox:dev
```

Docker Compose is also available:

```sh
docker compose up --build
```

## Notes

The image starts SSH by default, uses `john` as the primary user, and includes `omp`, `sfw`, and Frida client tooling.

The package set is expected to evolve as the toolkit grows.
