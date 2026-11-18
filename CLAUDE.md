# CLAUDE.md

Local Docker Compose stack: Apache Hop web UI + Apache Airflow (standalone). No application code, no unit tests.
Global working rules: `~/.claude/CLAUDE.md` (not copied here).

## Commands (all run and verified)
- `make up` / `make down` (down also deletes volumes) / `make ps` / `make logs`
- `make proof` prints the HTTP codes; `make verify` exits non-zero unless Hop (`http://localhost:18080/`, with redirects followed) and Airflow (`http://localhost:28080/health`) both return 200.
- `docker compose config -q` validates the compose file.

## Conventions
- Host ports 18080 (Hop) and 28080 (Airflow). Both containers listen on 8080 internally.
- Healthchecks run inside the image, so they may only use tools that image ships: hop-web has `wget`, airflow has `curl` but no `wget`.
- Images: `apache/hop-web:latest` (floating) and `apache/airflow:2.9.3-python3.10` (pinned).

## Do not touch
- `real-quick-check.txt` is the owner's scratch note; leave it.
- Work on a branch and open a PR; never push to `main`. CI (`.github/workflows/ci.yml`) boots the stack and runs `make verify`.
