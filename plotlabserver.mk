# This Makefile contains useful targets that can be included in downstream projects.

ifeq ($(filter plotlabserver.mk, $(notdir $(MAKEFILE_LIST))), plotlabserver.mk)

MAKEFLAGS += --no-print-directory
.EXPORT_ALL_VARIABLES: 
PLOTLABSERVER_PROJECT:=plotlabserver

PLOTLABSERVER_MAKEFILE_PATH:=$(strip $(shell realpath "$(shell dirname "$(lastword $(MAKEFILE_LIST))")"))
ifeq ($(SUBMODULES_PATH),)
    PLOTLABSERVER_SUBMODULES_PATH:=${PLOTLABSERVER_MAKEFILE_PATH}
else
    PLOTLABSERVER_SUBMODULES_PATH:=$(shell realpath ${SUBMODULES_PATH})
endif

MAKE_GADGETS_PATH:=${PLOTLABSERVER_SUBMODULES_PATH}/make_gadgets
ifeq ($(wildcard $(MAKE_GADGETS_PATH)/*),)
    $(info INFO: To clone submodules use: 'git submodules update --init --recursive')
    $(info INFO: To specify alternative path for submodules use: SUBMODULES_PATH="<path to submodules>" make build')
    $(info INFO: Default submodule path is: ${PLOTLABSERVER_SUBMODULES_PATH}')
    $(error "ERROR: ${MAKE_GADGETS_PATH} does not exist. Did you clone the submodules?")
endif
REPO_DIRECTORY:=${PLOTLABSERVER_MAKEFILE_PATH}

PLOTLABSERVER_TAG:=$(shell cd ${MAKE_GADGETS_PATH} && make get_sanitized_branch_name REPO_DIRECTORY=${REPO_DIRECTORY})
PLOTLABSERVER_IMAGE:=${PLOTLABSERVER_PROJECT}:${PLOTLABSERVER_TAG}
PLOTLABSERVER_BUILD_TAG:=${PLOTLABSERVER_TAG}
PLOTLABSERVER_BUILD_DOCKERFILE:="Dockerfile.${PLOTLABSERVER_PROJECT}_build"

PLOTLABSERVER_BUILD_PROJECT:="${PLOTLABSERVER_PROJECT}"

include ${MAKE_GADGETS_PATH}/make_gadgets.mk
include ${MAKE_GADGETS_PATH}/docker/docker-tools.mk
include ${PLOTLABSERVER_SUBMODULES_PATH}/plotlablib/plotlablib.mk

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

endif
