ifeq ($(OS),Windows_NT)
    OSTYPE = windows
    ifeq ($(PROCESSOR_ARCHITECTURE), AMD64)
        OSARCH = x86_64
    endif
    ifeq ($(PROCESSOR_ARCHITECTURE), ARM64)
        OSARCH = arm64
    endif
else
    OSTYPE = $(shell uname -s | tr '[:upper:]' '[:lower:]')
    OSARCH = $(shell uname -m | tr '[:upper:]' '[:lower:]')
    ifeq ($(OSARCH),aarch64)
        OSARCH = arm64
    endif
endif

# -----------------------------------------------------------------------------
# Container runtime selection.
#   Linux/Windows: docker (override with CONTAINER_RUNTIME=podman on Linux).
#   Darwin: probe in order container -> podman -> docker so Mac users can
#           avoid Docker Desktop. Override anywhere via the env var, e.g.
#           `CONTAINER_RUNTIME=podman make docker-build`.
# -----------------------------------------------------------------------------

ifeq ($(origin CONTAINER_RUNTIME), undefined)
    ifeq ($(OSTYPE),darwin)
        # Probe `container image ls` exit status (not stdout) so a half-installed
        # runtime — daemon not started, or `image` plugin missing — falls through to
        # podman/docker, while a working-but-imageless install (empty stdout, exit 0)
        # still selects `container`.
        ifneq ($(shell container image ls >/dev/null 2>&1 && echo ok),)
            CONTAINER_RUNTIME := container
        else ifneq ($(shell command -v podman 2>/dev/null),)
            CONTAINER_RUNTIME := podman
        else
            CONTAINER_RUNTIME := docker
        endif
    else
        CONTAINER_RUNTIME := docker
    endif
endif

# Apple `container` uses different verbs for image/container removal.
# Verified against `container` 0.12.3: `image` is singular (alias `i`),
# `delete` accepts container/image refs.
ifeq ($(CONTAINER_RUNTIME),container)
    CONTAINER_RMI := container image delete
    CONTAINER_RM  := container delete --force
else
    CONTAINER_RMI := $(CONTAINER_RUNTIME) rmi --force
    CONTAINER_RM  := $(CONTAINER_RUNTIME) rm --force
endif

# Compose: docker/podman compatible; Apple `container` has no compose support.
# Two patterns for guarding compose calls:
#   - Cleanup steps inside broader targets (e.g. clean-osarch-specific): wrap the
#     compose line in `ifneq ($(CONTAINER_RUNTIME),container) ... endif` so it's
#     silently skipped on Apple `container` while the rest of the target runs.
#   - Dedicated compose-only targets (none today, but added in the future):
#     branch on `$(CONTAINER_RUNTIME)` and `exit 1` with a clear message
#     pointing the user at CONTAINER_RUNTIME=docker or =podman.
ifeq ($(CONTAINER_RUNTIME),podman)
    COMPOSE := podman-compose
else
    COMPOSE := docker-compose
endif

# -----------------------------------------------------------------------------
# Build recipe macro.
#   Apple `container build` accepts only one --tag, so for that runtime we tag
#   the versioned ref and add the unversioned alias via a follow-up
#   `container image tag` (best-effort, prefixed with `-`). Other runtimes get
#   the original two-tag form.
#
# Usage:
#   $(eval $(call container_build_target,<target>,<extra-build-flags>,<version>))
# Examples:
#   $(eval $(call container_build_target,docker-build,,$(GIT_VERSION)))
#   $(eval $(call container_build_target,docker-build-osarch-specific,--platform linux/arm64,$(BUILD_VERSION)))
# -----------------------------------------------------------------------------

define container_build_target
.PHONY: $(1)
ifeq ($$(CONTAINER_RUNTIME),container)
$(1):
	$$(CONTAINER_RUNTIME) build $(2) \
		--tag $$(DOCKER_IMAGE_NAME):$(3) \
		.
	-container image tag $$(DOCKER_IMAGE_NAME):$(3) $$(DOCKER_IMAGE_NAME)
else
$(1):
	$$(CONTAINER_RUNTIME) build $(2) \
		--tag $$(DOCKER_IMAGE_NAME) \
		--tag $$(DOCKER_IMAGE_NAME):$(3) \
		.
endif
endef
