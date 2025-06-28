.DEFAULT_GOAL := all

SHELL := /bin/bash

makefile := $(abspath $(lastword $(MAKEFILE_LIST)))
makefile_dir := $(dir $(makefile))

# destination directory
dest ?= $(CURDIR)

arch := $(shell uname -m)

# gh
gh_version := $(subst v,,2.74.2)
gh_release := https://github.com/cli/cli/releases/download/v$(gh_version)
ifeq ($(arch),arm64)
  gh_archive := gh_$(gh_version)_macOS_arm64.zip
else
  gh_archive := gh_$(gh_version)_macOS_amd64.zip
endif

# ghq
ghq_release := https://github.com/x-motemen/ghq/releases/download/v1.8.0
ifeq ($(arch),arm64)
  ghq_archive := ghq_darwin_arm64.zip
else
  ghq_archive := ghq_darwin_amd64.zip
endif

# jq
jq_release := https://github.com/jqlang/jq/releases/download/jq-1.8.0
ifeq ($(arch),arm64)
  jq_executable := jq-macos-arm64
else
  jq_executable := jq-macos-amd64
endif

#-------------------------------------------------------------------------------

.PHONY: all
all: ## output targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(makefile) | awk 'BEGIN { FS = ":.*?## " }; { printf "\033[36m%-30s\033[0m %s\n", $$1, $$2 }'

.PHONY: clean
clean: ## remove files
	-$(RM) -f ./bw ./bw.zip ./gh ./gh.zip ./ghq ./ghq.zip ./jq

.PHONY: fetch
fetch: fetch-bw
fetch: fetch-gh
fetch: fetch-ghq
fetch: fetch-jq
fetch: ## fetch files

.PHONY: fetch-bw
fetch-bw: ## (subtarget) fetch Bitwarden CLI
	@echo "Fetching Bitwarden CLI..."
	curl --progress-bar -fsSL -o ./bw.zip 'https://bitwarden.com/download/?app=cli&platform=macos'
	unzip ./bw.zip bw

.PHONY: fetch-gh
fetch-gh: ## (subtarget) fetch GitHub CLI
	@echo "Fetching GitHub CLI..."
	curl --progress-bar -fsSL -o ./gh.zip '$(gh_release)/$(gh_archive)'
	unzip -j ./gh.zip '*/gh'

.PHONY: fetch-ghq
fetch-ghq: ## (subtarget) fetch ghq
	@echo "Fetching ghq..."
	curl --progress-bar -fsSL -o ./ghq.zip '$(ghq_release)/$(ghq_archive)'
	unzip -j ./ghq.zip '*/ghq'

.PHONY: fetch-jq
fetch-jq: ## (subtarget) fetch jq
	@echo "Fetching jq..."
	curl --progress-bar -fsSL -o ./jq '$(jq_release)/$(jq_executable)'
	chmod +x ./jq

.PHONY: test
test: targets := ./bw ./gh ./ghq ./jq
test: ## run tests
	@printf -- '%s\n' $(targets) | xargs -n 1 bash -c '$$0 --help 2>&1 >/dev/null && echo OK "$$0" || echo NG "$$0"'
	@echo done.
