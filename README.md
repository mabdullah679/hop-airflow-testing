# hop-airflow-testing

A Docker Compose stack that runs Apache Hop (web UI) and Apache Airflow (standalone mode) on localhost, with a one-command check that both answer HTTP 200.

```
make up
  |
  v
docker compose --> hop-web  (apache/hop-web)   host :18080 -> container :8080
              \--> airflow  (apache/airflow)   host :28080 -> container :8080
make verify --curl--> :18080/  (follow redirect)  and  :28080/health  --> both must be 200
```

Not local: the two images are pulled from Docker Hub on first run.

## Prerequisites
- Docker (Desktop or Engine) with the `docker compose` plugin, running
- `make` and `curl` on the host. `jq` is optional (only for pretty-printing Airflow's health JSON).
- Free host ports 18080 and 28080. Nothing else (no Java, Python or Airflow install) is needed on the host.

## Run it
1. `make up` (first run pulls images; Airflow needs roughly 1-2 minutes to initialise its database)
2. `make ps` until both containers show `healthy`
3. `make verify` (prints both codes, exit 0 only if both are 200)
4. Open http://localhost:18080/ (Hop) and http://localhost:28080/ (Airflow; `standalone` generates an admin user and prints the password in `make logs`)
5. `make down` to stop and delete volumes

If a port is taken, change the left-hand side of the `ports:` entry in `docker-compose.yml` and the matching URL in the `Makefile` (`proof` and `verify`). If `make verify` shows `000`, the service is not listening yet: run `make logs` and wait, or `docker compose ps`.

## What it does
| Action | Expected result |
|---|---|
| `make up` | starts `hop-web` and `airflow` in the background |
| `make ps` | both containers `healthy` once started |
| `make proof` | prints the HTTP code for each service |
| `make verify` | exit 0 only if both return 200 |
| `make logs` | follows both containers' logs |
| `make down` | removes containers and volumes |

Hop answers `302` on `/`, which is why the check follows redirects (`curl -L`).

## Tests
There is no unit-test suite. The check is `make verify` against a running stack; it needs Docker and network access to pull images. CI (`.github/workflows/ci.yml`) runs the same steps: validate the compose file, `make up`, poll `make verify`, `make down`, plus a gitleaks secrets scan.

## Layout
| Path | Role |
|---|---|
| [docker-compose.yml](docker-compose.yml) | the two services, ports and healthchecks |
| [Makefile](Makefile) | up/down/ps/logs/proof/verify |
| [.github/workflows/ci.yml](.github/workflows/ci.yml) | CI |
| [real-quick-check.txt](real-quick-check.txt) | the owner's scratch commands |
| [CLAUDE.md](CLAUDE.md) | notes for Claude Code sessions |

## Design notes
- Healthchecks use the tool each image actually ships (`wget` for Hop, `curl` for Airflow). The Airflow image has no `wget`, so a `wget` check can never pass and leaves the container permanently `unhealthy` even while the service works.
- `apache/hop-web:latest` floats, so the Hop base OS can change between pulls. Airflow is pinned to `2.9.3-python3.10`.
- Airflow `standalone` runs webserver, scheduler and triggerer in one container: fine for local testing, not a production layout.
- Compose `container_name` is fixed (`hop-web`, `airflow`), so two copies of this stack cannot run side by side.
