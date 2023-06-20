SHELL:=/bin/bash

ROOT_DIR:=$(shell dirname "$(realpath $(firstword $(MAKEFILE_LIST)))")
MAKEFLAGS += --no-print-directory

include plotlabserver.mk

.EXPORT_ALL_VARIABLES:
DOCKER_BUILDKIT?=1
DOCKER_CONFIG?=

SUBMODULES_PATH?=${ROOT_DIR}

include ${SUBMODULES_PATH}/ci_teststand/ci_teststand.mk

STB_DIRECTORY:=${ROOT_DIR}/stb
STB_FILES := $(wildcard $(STB_DIRECTORY)/*)
ifeq ($(STB_FILES),)
    $(shell git submodule update --init --recursive --remote --depth 1 --jobs 4 --single-branch ${ROOT_DIR}/stb || \
            git submodule update --init --recursive --remote --depth 1 --jobs 4 ${ROOT_DIR}/stb)
endif


USER := $(shell whoami)
UID := $(shell id -u)
GID := $(shell id -g)

.DEFAULT_GOAL := help


.PHONY: set_env 
set_env: 
	$(eval PROJECT := ${PLOTLABSERVER_PROJECT}) 
	$(eval TAG := ${PLOTLABSERVER_TAG})
	$(eval DOCKERFILE := ${PLOTLABSERVER_BUILD_DOCKERFILE})

.PHONY: all 
all: build

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
clean: clean_plotlablib set_env ## Clean plotlabserver docker images and delete build artifacts
	docker compose rm -f
	rm -f "${ROOT_DIR}/plotlabserver/include/plotlabserver/stb_image.h"
	rm -rf "${ROOT_DIR}/.log"
	rm -rf "${ROOT_DIR}/${PROJECT}/build"
	docker rm $$(docker ps -a -q --filter "ancestor=${PROJECT}:${TAG}") 2> /dev/null || true
	docker rm $$(docker ps -a -q --filter "ancestor=${PROJECT}_build:${TAG}") 2> /dev/null || true
	docker rmi $$(docker images -q ${PROJECT}_build:${TAG}) --force 2> /dev/null || true
	docker rmi $$(docker images -q ${PROJECT}:${TAG}) --force 2> /dev/null || true

.PHONY: build_fast
build_fast: set_env ## Build plotlabserver docker context only if it has not already been built. Will not attempt to rebuild.
	@if [ -n "$$(docker images -q ${PROJECT}_build:${TAG})" ]; then \
        echo "Docker image: ${PROJECT}_build:${TAG} already build, skipping build."; \
    else \
        make build;\
    fi

	@if [ -n "$$(docker images -q ${PROJECT}:${TAG})" ]; then \
        echo "Docker image: ${PROJECT}:${TAG} already build, skipping build."; \
    else \
        docker compose build;\
    fi
	docker cp $$(docker create --rm ${PROJECT}_build:${TAG}):/tmp/${PROJECT}/${PROJECT}/build "${ROOT_DIR}/${PROJECT}"

.PHONY: build
build: set_env build_plotlablib
	rm -rf "${ROOT_DIR}/${PROJECT}/build"
	docker build --network host \
                 -f ${DOCKERFILE} \
                 --tag ${PROJECT}_build:${TAG} \
                 --build-arg PROJECT=${PROJECT} \
                 --build-arg PLOTLABLIB_TAG=${PLOTLABLIB_TAG} .
	docker cp $$(docker create --rm ${PROJECT}_build:${TAG}):/tmp/${PROJECT}/${PROJECT}/build "${ROOT_DIR}/${PROJECT}"

.PHONY: docker_compose_build
docker_compose_build:
	docker compose build


.PHONY: stop_plotlabserver 
stop_plotlabserver:
	docker compose down
	docker compose rm -f
	docker stop plotlabserver 2> /dev/null || true
	docker rm plotlabserver 2> /dev/null || true

.PHONY: start_plotlabserver 
start_plotlabserver: stop_plotlabserver build_fast
	mkdir -p .log
	pwd && docker compose rm -f
	pwd && xhost + 1> /dev/null && docker compose up --force-recreate plotlabserver; xhost - 1> /dev/null; docker compose rm --force

.PHONY: start_plotlabserver_detached 
start_plotlabserver_detached: stop_plotlabserver build_fast
	mkdir -p .log
	xhost + 1> /dev/null && docker compose up --force-recreate -d &

.PHONY: view_plotlab_server_logs 
view_plotlabserver_logs: ## View plotlabserver logs in detached mode
	docker compose logs -f plotlabserver

.PHONY: ci_build
ci_build: build docker_compose_build

.PHONY: test
test: ci_test

