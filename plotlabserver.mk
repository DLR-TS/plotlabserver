# This Makefile contains useful targets that can be included in downstream projects.

#ifndef plotlabserver_MAKEFILE_PATH

MAKEFLAGS += --no-print-directory

.EXPORT_ALL_VARIABLES:
plotlabserver_project:=plotlabserver
PLOTLABSERVER_PROJECT:=${plotlabserver_project}

#plotlabserver_MAKEFILE_PATH:=$(shell realpath "$(lastword $(MAKEFILE_LIST))" | sed "s|/${plotlabserver_project}.mk||g")
plotlabserver_MAKEFILE_PATH:= $(shell dirname "$(abspath "$(lastword $(MAKEFILE_LIST))")")

plotlabserver_tag:=$(shell cd "${plotlabserver_MAKEFILE_PATH}/plotlablib/make_gadgets" && make get_sanitized_branch_name REPO_DIRECTORY=${plotlabserver_MAKEFILE_PATH})
PLOTLABSERVER_TAG:=${plotlabserver_tag}

plotlabserver_image:=${plotlabserver_project}:${plotlabserver_tag}
PLOTLABSERVER_IMAGE:=${plotlabserver_image}

PLOTLABSERVER_BUILD_TAG:=${plotlabserver_tag}
PLOTLABSERVER_BUILD_TAG:=${plotlabserver_tag}

PLOTLABSERVER_BUILD_DOCKERFILE:="Dockerfile.${plotlabserver_project}_build"

PLOTLABSERVER_BUILD_TAG:=${plotlabserver_tag}
plotlabserver_build_tag:=${plotlabserver_tag}
PLOTLABSERVER_BUILD_DOCKERFILE:="Dockerfile.${plotlabserver_project}_build"

PLOTLABSERVER_BUILD_PROJECT:="${plotlabserver_project}"
plotlabserver_build_project:="${plotlabserver_project}"

.PHONY: build_plotlabserver 
build_plotlabserver: ## Build plotlabserver
	cd "${plotlabserver_MAKEFILE_PATH}" && make

.PHONY: clean_plotlabserver
clean_plotlabserver: ## Clean plotlabserver build artifacts
	cd "${plotlabserver_MAKEFILE_PATH}" && make clean

.PHONY: branch_plotlabserver
branch_plotlabserver: ## Returns the current docker safe/sanitized branch for plotlabserver
	@printf "%s\n" ${plotlabserver_tag}

.PHONY: image_plotlabserver
image_plotlabserver: ## Returns the current docker image name for plotlabserver
	@printf "%s\n" ${plotlabserver_image}

.PHONY: update_plotlabserver
update_plotlabserver:
	cd "${plotlabserver_MAKEFILE_PATH}" && git pull

#endif
