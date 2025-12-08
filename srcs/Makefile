SHELL := /bin/bash

COMPOSE := docker compose
COMPOSE_FILE := docker-compose.yml

.PHONY: all build up down start stop logs ps clean fclean re

all: build

build:
	$(COMPOSE) -f $(COMPOSE_FILE) build --no-cache

up:
	$(COMPOSE) -f $(COMPOSE_FILE) up -d

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
