# xnet-core

XNet Core networking engine.

## Overview

Hard fork of ZeroTier One 1.14.2 (Apache 2.0 — BSL change date has passed). Rebranded with custom default world (planet) for the XNet network. SSO disabled, vendor unspecified.

## Binaries

| Original | Rebranded |
|---|---|
| zerotier-one | xnet-one |
| zerotier-cli | xnet-cli |
| zerotier-idtool | xnet-idtool |

Home directory: `/var/lib/xnet`

## Build

Linux:

```sh
make
```

See `Makefile` for targets and options.

## Run

Runs as a systemd service:

```sh
sudo systemctl start xnet-one
sudo systemctl enable xnet-one
```

## License

Apache 2.0
