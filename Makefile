SHELL:=/bin/bash

ROOT_DIR:=$(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")
MAKEFLAGS += --no-print-directory


.EXPORT_ALL_VARIABLES:
DOCKER_BUILDKIT?=1
DOCKER_CONFIG?=

include plotlablib/make_gadgets/make_gadgets.mk
include plotlablib/make_gadgets/docker/docker-tools.mk
include plotlablib/plotlablib.mk
include plotlabserver.mk

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
clean: set_env ## Clean plotlabserver docker images and delete build artifacts
	docker compose rm -f
	cd plotlablib && \
    make clean
	rm -f "${ROOT_DIR}/plotlabserver/include/plotlabserver/stb_image.h"
	rm -rf "${ROOT_DIR}/.log"
	rm -rf "${ROOT_DIR}/${PROJECT}/build"
	docker rm $$(docker ps -a -q --filter "ancestor=${PROJECT}:${TAG}") 2> /dev/null || true
	docker rm $$(docker ps -a -q --filter "ancestor=${PROJECT}_build:${TAG}") 2> /dev/null || true
	docker rmi $$(docker images -q ${PROJECT}_build:${TAG}) --force 2> /dev/null || true
	docker rmi $$(docker images -q ${PROJECT}:${TAG}) --force 2> /dev/null || true

.PHONY: build_fast
build_fast: ## Build plotlabserver docker context only if it has not already been built. Will not attempt to rebuild.
	[ -n "$$(docker images -q ${PROJECT}_build:${TAG})" ] || make build
	[ -n "$$(docker images -q ${PROJECT}:${TAG})" ] || docker compose build plotlabserver

.PHONY: build
build: set_env clean build_plotlablib
	rm -rf "${ROOT_DIR}/${PROJECT}/build"
	docker build --network host \
				 -f ${DOCKERFILE} \
                 --tag ${PROJECT}_build:${TAG} \
                 --build-arg PROJECT=${PROJECT} \
                 --build-arg PLOTLABLIB_TAG=${PLOTLABLIB_TAG} .
	docker cp $$(docker create --rm ${PROJECT}_build:${TAG}):/tmp/${PROJECT}/${PROJECT}/build "${ROOT_DIR}/${PROJECT}"

.PHONY: stop_plotlabserver 
stop_plotlabserver:
	docker compose down
	docker compose rm -f
	docker stop plotlabserver 2> /dev/null || true
	docker rm plotlabserver 2> /dev/null || true

.PHONY: start_plotlabserver 
start_plotlabserver: stop_plotlabserver build_fast
	mkdir -p .log
	docker compose rm -f
	xhost + 1> /dev/null && docker compose up --force-recreate plotlabserver; xhost - 1> /dev/null; docker compose rm --force

.PHONY: start_plotlabserver_detached 
start_plotlabserver_detached: stop_plotlabserver build_fast
	mkdir -p .log
	xhost + 1> /dev/null && docker compose up --rm --force-recreate -d &

.PHONY: build_plotlabserver_compile 
build_plotlabserver_compile:
	@cd "${ROOT_DIR}/plotlabserver/include/plotlabserver" && \
	ln -sf ../../../stb/stb_image.h stb_image.h
	cd "${ROOT_DIR}/plotlabserver" && \
	bash build.sh

.PHONY: view_plotlab_server_logs 
view_plotlabserver_logs: ## View plotlabserver logs in detached mode
	docker compose logs -f plotlabserver

