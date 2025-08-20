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
