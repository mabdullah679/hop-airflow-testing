.PHONY: up down ps logs proof verify

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

# Fails (non-zero exit) unless both services answer HTTP 200. `proof` only prints codes.
verify:
	@hop=$$(curl -s -L -o /dev/null -w "%{http_code}" http://localhost:18080/); \
	air=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:28080/health); \
	echo "Hop: $$hop  Airflow: $$air"; \
	[ "$$hop" = "200" ] && [ "$$air" = "200" ]
