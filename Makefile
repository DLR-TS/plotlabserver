SHELL:=/bin/bash

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
MAKEFLAGS += --no-print-directory

.EXPORT_ALL_VARIABLES:
DOCKER_BUILDKIT?=1
DOCKER_CONFIG?=

DOCKER_GID := $(shell getent group | grep docker | cut -d":" -f3)
USER := $(shell whoami)
UID := $(shell id -u)
GID := $(shell id -g)

.DEFAULT_GOAL := help

STB_DIRECTORY = "${ROOT_DIR}/stb"

$(STB_DIRECTORY):
	@echo "ERROR: STB ${STB_DIRECTORY} does not exist."
	@echo "  Did you clone or init the submodules?"
	@exit 1

.PHONY: help 
help:
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

PLOTLABSERVER_BUILD_PROJECT="plotlabserver"
PLOTLABSERVER_BUILD_VERSION="latest"
PLOTLABSERVER_BUILD_TAG="${PLOTLABSERVER_BUILD_PROJECT}_build:${PLOTLABSERVER_BUILD_VERSION}"
PLOTLABSERVER_BUILD_DOCKERFILE="Dockerfile.${PLOTLABSERVER_BUILD_PROJECT}_build"

PLOTLABSERVER_PROJECT="plotlabserver"
PLOTLABSERVER_VERSION="latest"
PLOTLABSERVER_TAG="${PLOTLABSERVER_PROJECT}:${PLOTLABSERVER_VERSION}"


.PHONY: set_env 
set_env: 
	$(eval PROJECT := ${PLOTLABSERVER_BUILD_PROJECT}) 
	$(eval TAG := ${PLOTLABSERVER_BUILD_TAG})
	$(eval DOCKERFILE := ${PLOTLABSERVER_BUILD_DOCKERFILE})

.PHONY: all 
all: clean build

.PHONY: up 
up: ## Starts plotlabserver instance, interactive
	make start_plotlabserver

.PHONY: up-detached
up-detached: ## Starts plotlabserver instance in detached mode, non-interactive
	make start_plotlabserver_detached


.PHONY: down 
down: ## Stops plotlabserver instance
	make stop_plotlabserver
	docker compose rm -f

.PHONY: clean 
clean: set_env
	docker compose rm -f
	cd plotlablib && \
    make clean
	rm -rf "${ROOT_DIR}/${PROJECT}/build"
	docker rm $$(docker ps -a -q --filter "ancestor=${TAG}") 2> /dev/null || true
	docker rmi $$(docker images -q ${TAG}) 2> /dev/null || true
	docker rmi $$(docker images -q ${PLOTLABSERVER_TAG}) 2> /dev/null || true

.PHONY: build
build: set_env clean
	rm -rf ${ROOT_DIR}/${PROJECT}/build
	cd plotlablib && \
    make
	docker build --network host \
                 --tag $(shell echo ${TAG} | tr A-Z a-z) \
				 -f ${DOCKERFILE} \
                 --build-arg PROJECT=${PROJECT} .
	mkdir -p "${ROOT_DIR}/tmp/${PROJECT}"
	docker cp $$(docker create --rm $(shell echo ${TAG} | tr A-Z a-z)):/tmp/${PROJECT}/${PROJECT}/build ${ROOT_DIR}/${PROJECT}

.PHONY: stop_plotlabserver 
stop_plotlabserver:
	docker compose down
	docker compose rm -f
	docker stop plotlabserver 2> /dev/null || true
	docker rm plotlabserver 2> /dev/null || true

.PHONY: start_plotlabserver 
start_plotlabserver: stop_plotlabserver
	@[ -n "$$(docker images -q ${PLOTLABSERVER_BUILD_TAG})" ] || make build
	@[ -n "$$(docker images -q ${PLOTLABSERVER_TAG})" ] || docker compose build plotlabserver
	mkdir -p .log
	docker compose rm -f
	xhost + 1> /dev/null && docker compose up --force-recreate plotlabserver; xhost - 1> /dev/null

.PHONY: start_plotlabserver_detached 
start_plotlabserver_detached: stop_plotlabserver
	@[ -n "$$(docker images -q ${PLOTLABSERVER_BUILD_TAG})" ] || make build_
	@[ -n "$$(docker images -q ${PLOTLABSERVER_TAG})" ] || docker compose build plotlabserver
	mkdir -p .log
	xhost + 1> /dev/null && docker compose up --force-recreate -d &

.PHONY: build_plotlabserver 
build_plotlabserver:
	@cd "${ROOT_DIR}/plotlabserver/include/plotlabserver" && \
	ln -sf ../../../stb/stb_image.h stb_image.h
	cd "${ROOT_DIR}/plotlabserver" && \
	bash build.sh

.PHONY: view_plotlab_server_logs 
view_plotlabserver_logs: ## View plotlabserver logs in detached mode
	docker compose logs -f plotlabserver

.PHONY: docker_clean 
docker_clean:
	rm -f "${ROOT_DIR}/plotlabserver/include/plotlabserver/stb_image.h"
	docker rmi $$(docker images --filter "dangling=true" -q) --force
