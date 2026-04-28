# xnet-one

Docker deployment for xnet-core daemon and portal.

## Overview

Packages the xnet-core daemon, xnet-portal, and xnet-speed test server into a docker-compose stack. Targets ARM64 on AWS.

## Services

| Service | Port |
|---|---|
| xnet-core daemon | — |
| xnet-portal | :3001 |
| xnet-speed | :19980 |

## Run

```sh
docker-compose up -d
```

## License

Apache 2.0
