SHELL := /bin/bash

COMPOSE := docker compose
COMPOSE_FILE := docker-compose.yml

.PHONY: all build up down start stop logs ps clean fclean re debug sh wpsh ngsh dbsh

all: up

build:
	$(COMPOSE) -f $(COMPOSE_FILE) build --no-cache

up:
	$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

down:
	$(COMPOSE) -f $(COMPOSE_FILE) down

start:
	$(COMPOSE) -f $(COMPOSE_FILE) start

stop:
	$(COMPOSE) -f $(COMPOSE_FILE) stop

logs:
	$(COMPOSE) -f $(COMPOSE_FILE) logs -f

ps:
	$(COMPOSE) -f $(COMPOSE_FILE) ps

clean:
	$(COMPOSE) -f $(COMPOSE_FILE) down --volumes --remove-orphans

# Remove all images built by this compose project (no nginx)
fclean:
	$(COMPOSE) -f $(COMPOSE_FILE) down --volumes --remove-orphans --rmi local || true
	docker image prune -f || true

re: fclean all

# Debug helpers: run a shell in a service container and remove when exit
debug:
	@echo "Usage: make sh SERVICE=<service> (nginx|wordpress|mariadb)" && exit 0

sh:
	@if [ -z "$(SERVICE)" ]; then echo "SERVICE is required (e.g., SERVICE=wordpress)"; exit 1; fi
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm --entrypoint /bin/sh $(SERVICE)

wpsh:
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm --entrypoint /bin/sh wordpress

ngsh:
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm --entrypoint /bin/sh nginx

dbsh:
	$(COMPOSE) -f $(COMPOSE_FILE) run --rm --entrypoint /bin/sh mariadb
