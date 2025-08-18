
===============================================================================
HOP + AIRFLOW LOCAL TESTING STACK (PLAIN-TEXT README)
===============================================================================

Project root:
  /Users/muhammadabdullah/Documents/hop-airflow-testing

Goal:
  Deploy Apache Hop (web UI) and Apache Airflow (standalone) to Linux containers
  on localhost, then prove service health via HTTP curl (expect 200 OK).

Result (what we achieved):
  - Hop:   curl -L http://localhost:18080/  -> 200
  - Airflow: curl http://localhost:28080/health -> 200

-------------------------------------------------------------------------------
1) PREREQUISITES (macOS with Docker Desktop)
-------------------------------------------------------------------------------
- Docker Desktop installed and running.
- Terminal access (zsh/bash).
- curl and jq installed (jq optional, used to pretty-print JSON).

Verify Docker:
  docker version
  docker info

Optional sanity checks:
  docker run --rm hello-world
  docker system df

-------------------------------------------------------------------------------
2) PROJECT FILES (CURRENT WORKING VERSION)
-------------------------------------------------------------------------------

2.1 docker-compose.yml
----------------------
services:
  hop-web:
    image: apache/hop-web:latest
    container_name: hop-web
    ports:
      - "18080:8080"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 20s

  airflow:
    image: apache/airflow:2.9.3-python3.10
    container_name: airflow
    command: standalone
    ports:
      - "28080:8080"
    environment:
      AIRFLOW__WEBSERVER__EXPOSE_CONFIG: "True"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 30
      start_period: 40s


2.2 Makefile
------------
up:
	docker compose up -d

down:
	docker compose down -v

ps:
	docker compose ps

logs:
	docker compose logs -f hop-web airflow

proof:
	@printf "Hop:     " && curl -s -L -o /dev/null -w "%{http_code}\n" http://localhost:18080/
	@printf "Airflow: " && curl -s -o /dev/null -w "%{http_code}\n" http://localhost:28080/health


-------------------------------------------------------------------------------
3) RUN BOOK (COMMANDS YOU ACTUALLY RUN)
-------------------------------------------------------------------------------

Bring up the stack:
  make up
  make ps

Follow logs (optional):
  make logs

Prove HTTP 200 responses:
  make proof
  # or directly:
  curl -s -L -o /dev/null -w "%{http_code}\n" http://localhost:18080/
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:28080/health

Inspect Airflow health payload (optional):
  curl -s http://localhost:28080/health | jq .

Tear down everything (including volumes):
  make down


-------------------------------------------------------------------------------
4) CONTAINER OS CHECKS (CONFIRM DEBIAN-FAMILY LINUX)
-------------------------------------------------------------------------------

Check inside running containers:
  docker exec -it hop-web cat /etc/os-release
  docker exec -it airflow cat /etc/os-release

Observed in this run:
  - hop-web  -> Ubuntu 24.04.2 LTS (ID_LIKE=debian)
  - airflow  -> Debian GNU/Linux 12 (bookworm)

Both satisfy "Linux Debian image docker containers" (Debian family).


-------------------------------------------------------------------------------
5) NOTES, QUIRKS, AND GOTCHAS
-------------------------------------------------------------------------------

- Hop returns 302 on the root path. Use -L to follow redirects for a clean 200:
    curl -s -L -o /dev/null -w "%{http_code}\n" http://localhost:18080/

- Airflow "standalone" handles DB init, webserver, scheduler, triggerer, and
  creates an admin user automatically. Health endpoint:
    http://localhost:28080/health

- If curl returns 000, the service is not listening yet or the container is
  not healthy. Check:
    docker compose ps
    docker logs --tail=200 airflow
    docker logs --tail=200 hop-web

- Orphan container warning:
    "Found orphan containers ([hop-server])..."
  This just means a previous compose service name still has a container. Clean up:
    docker compose up -d --remove-orphans
  or remove the container manually:
    docker rm -f hop-server

- Proxy/Networking (Docker Desktop):
  If you have HTTP/HTTPS proxy settings, they can affect pulls or healthchecks.
  Adjust in Docker Desktop settings or unset for local traffic if needed.

- Disk cleanup (handy commands):
    docker system df
    docker system prune -af --volumes


-------------------------------------------------------------------------------
6) REPRODUCIBILITY AND PINNING
-------------------------------------------------------------------------------

- Current images:
    apache/hop-web:latest
    apache/airflow:2.9.3-python3.10

- For long-lived docs, consider pinning digests:
    image: apache/airflow@sha256:<digest>

- Add restart policy if you want containers to auto-restart on reboot:
    restart: unless-stopped


-------------------------------------------------------------------------------
7) ACCEPTANCE CRITERIA (WHAT COUNTS AS "UP")
-------------------------------------------------------------------------------

- Hop is reachable on localhost:18080 with HTTP 200 when following redirects.
  Acceptance command:
    curl -s -L -o /dev/null -w "%{http_code}\n" http://localhost:18080/
  Expect:
    200

- Airflow health endpoint returns 200:
    curl -s -o /dev/null -w "%{http_code}\n" http://localhost:28080/health
  Expect:
    200

- Optional: show subsystem health JSON (metadatabase/scheduler/triggerer):
    curl -s http://localhost:28080/health | jq .


-------------------------------------------------------------------------------
8) TROUBLESHOOTING QUICK REFERENCE
-------------------------------------------------------------------------------

Check process state:
  docker compose ps

Check logs:
  docker compose logs -f hop-web airflow

Check container health details:
  docker inspect --format='{{json .State.Health}}' hop-web | jq .
  docker inspect --format='{{json .State.Health}}' airflow | jq .

Verify ports are free on host:
  lsof -i :18080
  lsof -i :28080

Restart the stack cleanly:
  docker compose down -v && docker compose up -d

If Airflow health stays 000:
  - Wait 30–90s on first boot (DB migration, FAB roles creation).
  - Confirm logs don’t show binding errors (look for “Listening at: http://0.0.0.0:8080”).
  - Ensure nothing else is bound to host port 28080.


-------------------------------------------------------------------------------
9) WHY A SINGLE COMPOSE FILE
-------------------------------------------------------------------------------

- Single command orchestration (up/down/logs).
- Shared network with service name DNS.
- Clear, versioned infrastructure as code.
- Independent lifecycles (Hop and Airflow have no runtime dependency).


-------------------------------------------------------------------------------
END OF FILE
-------------------------------------------------------------------------------
