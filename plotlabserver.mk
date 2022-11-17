# This Makefile contains useful targets that can be included in downstream projects.

#ifndef PLOTLABSERVER_MAKEFILE_PATH

MAKEFLAGS += --no-print-directory

.EXPORT_ALL_VARIABLES:
PLOTLABSERVER_PROJECT:=plotlabserver

#plotlabserver_MAKEFILE_PATH:=$(shell realpath "$(lastword $(MAKEFILE_LIST))" | sed "s|/${plotlabserver_project}.mk||g")
PLOTLABSERVER_MAKEFILE_PATH:= $(shell dirname "$(abspath "$(lastword $(MAKEFILE_LIST))")")
MAKE_GADGETS_PATH:=${PLOTLABSERVER_MAKEFILE_PATH}/plotlablib/make_gadgets
REPO_DIRECTORY:=${PLOTLABSERVER_MAKEFILE_PATH}

PLOTLABSERVER_TAG:=$(shell cd ${MAKE_GADGETS_PATH} && make get_sanitized_branch_name REPO_DIRECTORY=${REPO_DIRECTORY})
PLOTLABSERVER_IMAGE:=${PLOTLABSERVER_PROJECT}:${PLOTLABSERVER_TAG}
PLOTLABSERVER_BUILD_TAG:=${PLOTLABSERVER_TAG}
PLOTLABSERVER_BUILD_DOCKERFILE:="Dockerfile.${PLOTLABSERVER_PROJECT}_build"

PLOTLABSERVER_BUILD_PROJECT:="${PLOTLABSERVER_PROJECT}"

.PHONY: build_plotlabserver 
build_plotlabserver: ## Build plotlabserver
	cd "${PLOTLABSERVER_MAKEFILE_PATH}" && make build

.PHONY: build_fast_plotlabserver 
build_fast_plotlabserver: ## Build plotlabserver
	cd "${PLOTLABSERVER_MAKEFILE_PATH}" && make build_fast

.PHONY: clean_plotlabserver
clean_plotlabserver: ## Clean plotlabserver build artifacts
	cd "${PLOTLABSERVER_MAKEFILE_PATH}" && make clean

.PHONY: branch_plotlabserver
branch_plotlabserver: ## Returns the current docker safe/sanitized branch for plotlabserver
	@printf "%s\n" ${PLOTLABSERVER_TAG}

.PHONY: image_plotlabserver
image_plotlabserver: ## Returns the current docker image name for plotlabserver
	@printf "%s\n" ${PLOTLABSERVER_IMAGE}

.PHONY: update_plotlabserver
update_plotlabserver:
	cd "${PLOTLABSERVER_MAKEFILE_PATH}" && git pull

#endif
