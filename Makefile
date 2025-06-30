.DEFAULT_GOAL := all

SHELL := /bin/bash

makefile := $(abspath $(lastword $(MAKEFILE_LIST)))
makefile_dir := $(dir $(makefile))

# destination directory
dest ?= $(CURDIR)

arch := $(shell uname -m)

# gh
# renovate: datasource=github-tags depName=cli/cli
gh_version := v2.74.2
gh_release := https://github.com/cli/cli/releases/download/$(gh_version)
ifeq ($(arch),arm64)
  gh_archive := gh_$(subst v,,$(gh_version))_macOS_arm64.zip
else
  gh_archive := gh_$(subst v,,$(gh_version))_macOS_amd64.zip
endif

# ghq
# renovate: datasource=github-tags depName=x-motemen/ghq
ghq_version := v1.8.0
ghq_release := https://github.com/x-motemen/ghq/releases/download/$(ghq_version)
ifeq ($(arch),arm64)
  ghq_archive := ghq_darwin_arm64.zip
else
  ghq_archive := ghq_darwin_amd64.zip
endif

# jq
# renovate: datasource=github-tags depName=jqlang/jq
jq_version := jq-1.8.0
jq_release := https://github.com/jqlang/jq/releases/download/$(jq_version)
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
	-$(RM) -f ./bw ./bw.zip ./gh ./gh.zip ./ghq ./ghq.zip ./jq ./macports.pkg

.PHONY: fetch
fetch: fetch-bw
fetch: fetch-gh
fetch: fetch-ghq
fetch: fetch-jq
fetch: fetch-macports
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

.PHONY: fetch-macports
fetch-macports: macos_version := $(shell sw_vers --productVersion | awk -F . '{ print $$1 }')
fetch-macports: ## (subtarget) fetch MacPorts
	@echo "Fetching MacPorts..."
	curl --progress-bar -fsSL 'https://www.macports.org/install.php' | grep -Eo '"[^"]*\.pkg"' | sort -ruV | tr -d '"' | tee macports.txt
	curl --progress-bar -fsSL -o ./macports.pkg "$$(grep -- '-$(macos_version)-' macports.txt)"
	$(RM) -f macports.txt

.PHONY: install-macports
install-macports: ## install MacPorts
	@echo "Installing MacPorts..."
	sudo installer -pkg ./macports.pkg -target /

.PHONY: test
test: binaries := ./bw ./gh ./ghq ./jq
test: ## run tests
	@printf -- '%s\n' $(binaries) | xargs -n 1 bash -c 'test -x $$0 && echo OK "$$0" || echo NG "$$0"'
	@test -r ./macports.pkg && echo OK ./macports.pkg || echo NG ./macports.pkg
	@echo done.
