# Windows runners: make defaults to cmd.exe, recipes are written for a POSIX shell.
SHELL := bash

FVM          ?= fvm
FLUTTER      ?= $(FVM) flutter
DART         ?= $(FVM) dart
FLAVOR       ?= development
MODE         ?= release
BUILD_NUMBER ?= 1
WEB_PORT     ?= 9090
BASE_HREF    ?= /
DOCKER_IMAGE ?= fladder:latest
DEVICE       ?=
ARGS         ?=

BN         = --build-number=$(BUILD_NUMBER)
FLAVOR_ARG = --flavor $(FLAVOR)
BUILD_ARGS = --$(MODE) $(BN) $(ARGS)
RUN_ARGS   = $(FLAVOR_ARG) $(if $(DEVICE),-d $(DEVICE)) $(ARGS)

UNAME := $(shell uname -s)
HOST  := $(if $(findstring Darwin,$(UNAME)),macos,$(if $(findstring Linux,$(UNAME)),linux,windows))

# Only Android/iOS/macOS define product flavors; the flag is rejected elsewhere.
build-windows build-linux build-web run-linux run-windows: FLAVOR_ARG :=

.DEFAULT_GOAL := help
.PHONY: help all deps pigeon build-runner l10n codegen bootstrap watch regen icons \
	format format-check analyze lint test check ci \
	run run-htpc run-web \
	build-apk build-aab build-ipa build-macos build-dmg \
	build-windows build-linux build-web build-appimage build-docker \
	release-android clean clean-gen distclean

help: ## List targets
	@grep -E '^[a-z][a-zA-Z0-9_%-]*:.*##' $(MAKEFILE_LIST) | \
		awk -F':.*## ' '{printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

all: bootstrap check release-$(HOST) ## Complete setup to release build

## Setup & codegen

deps: ## Fetch pub dependencies
	$(FLUTTER) pub get

pigeon: ## Generate platform-channel bindings
	for f in pigeons/*.dart; do $(DART) run pigeon --input "$$f"; done

build-runner: ## Run all build_runner generators once
	$(DART) run build_runner build --delete-conflicting-outputs

l10n: ## Generate localizations
	$(FLUTTER) gen-l10n

codegen: pigeon build-runner l10n format ## Run all generators and format

bootstrap: deps codegen ## Prepare fresh checkout: deps + codegen

watch: ## build_runner in watch mode
	$(DART) run build_runner watch --delete-conflicting-outputs

regen: clean-gen codegen ## Regenerate everything from scratch

icons: ## Regenerate launcher icons
	$(DART) run icons_launcher:create --flavors development,production

## Quality

format: ## Format all Dart sources, generated included
	$(DART) format lib test pigeons

format-check: ## Verify correct formatting
	$(DART) format --set-exit-if-changed --output=none lib test pigeons

analyze: ## Static analysis, fail on infos
	$(FLUTTER) analyze --fatal-infos

lint: format-check analyze ## Format check + analysis

test: ## Run tests (ARGS= for a file or --plain-name)
	$(FLUTTER) test $(ARGS)

check: lint test ## Lint + tests
ci: bootstrap lint ## Clean-tree CI equivalent

## Run -- FLAVOR=development|production, DEVICE=, ARGS= pass through

run: ## Debug run
	$(FLUTTER) run $(RUN_ARGS)

run-%: ## Debug run on a named device, e.g. run-linux, run-android
	$(FLUTTER) run -d $* $(RUN_ARGS)

run-htpc: ## Debug run with TV/HTPC layout
	$(FLUTTER) run -a --htpc $(RUN_ARGS)

run-web: ## Debug run in Chrome (web has no flavors)
	$(FLUTTER) run -d chrome --web-port $(WEB_PORT) $(ARGS)

## Build -- MODE=debug|profile|release, FLAVOR= as above.
## Assumes generated code is present; release-<target> runs codegen first.

build-apk: ## Split APKs (debug-signed if android/app/key.properties is absent)
	$(FLUTTER) build apk --split-per-abi $(FLAVOR_ARG) $(BUILD_ARGS)

build-aab: ## App bundle
	$(FLUTTER) build appbundle $(FLAVOR_ARG) $(BUILD_ARGS)

build-ipa: ## Unsigned IPA
	$(FLUTTER) build ipa --no-codesign $(FLAVOR_ARG) $(BUILD_ARGS)

build-macos: ## macOS app
	$(FLUTTER) build macos $(FLAVOR_ARG) $(BUILD_ARGS)

build-windows: ## Windows app
	$(FLUTTER) build windows $(BUILD_ARGS)

build-linux: ## Linux app
	$(FLUTTER) build linux $(BUILD_ARGS)

build-web: ## Web bundle (BASE_HREF= for subpath hosting)
	$(FLUTTER) build web --base-href $(BASE_HREF) $(BUILD_ARGS)

# create_dmg.sh, AppImageBuilder.yml and the Dockerfile read fixed
# release-build paths, so these pin MODE/FLAVOR rather than inherit them.
build-dmg: FLAVOR := production
build-dmg: MODE := release
build-dmg: build-macos ## macOS app + DMG (macOS host)
	./scripts/create_dmg.sh

build-appimage: MODE := release
build-appimage: build-linux ## Linux AppImage (needs appimage-builder)
	appimage-builder --recipe AppImageBuilder.yml

build-docker: MODE := release
build-docker: build-web ## Web bundle + docker image
	docker build -t $(DOCKER_IMAGE) .

release-%: FLAVOR := production
release-%: MODE := release
release-%: codegen build-% ## codegen + production build-<target>, e.g. release-web
	@:

release-android: FLAVOR := production
release-android: MODE := release
release-android: codegen build-apk build-aab ## codegen + APKs + AAB

## Clean

clean: ## flutter clean
	$(FLUTTER) clean

clean-gen: ## Delete generated sources
	find lib -type f \( -name '*.g.dart' -o -name '*.freezed.dart' -o -name '*.mapper.dart' \
		-o -name '*.gr.dart' -o -name '*.chopper.dart' -o -name '*.swagger.dart' \) -delete
	rm -rf lib/l10n/generated
	find android ios macos -type f \( -name '*.g.kt' -o -name '*.g.swift' \) -delete

distclean: clean clean-gen ## flutter clean + delete generated sources
