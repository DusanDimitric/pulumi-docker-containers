PROJECT_NAME := Pulumi Fabric
SUB_PROJECTS := sdk/nodejs
include build/common.mk

PROJECT      := github.com/pulumi/pulumi
PROJECT_PKGS := $(shell go list ./cmd/... ./pkg/... | grep -v /vendor/)
VERSION      := $(shell git describe --tags 2>/dev/null)

GOMETALINTERBIN := gometalinter
GOMETALINTER    := ${GOMETALINTERBIN} --config=Gometalinter.json

TESTPARALLELISM := 10

build::
	go install -ldflags "-X main.version=${VERSION}" ${PROJECT}
	go install -ldflags "-X main.version=${VERSION}" ${PROJECT}/cmd/lumidl

install::
	GOBIN=$(PULUMI_BIN)	go install -ldflags "-X main.version=${VERSION}" ${PROJECT}

LINT_SUPPRESS="or be unexported"
lint::
	$(GOMETALINTER) main.go | grep -vE ${LINT_SUPPRESS} | sort ; exit $$(($${PIPESTATUS[1]}-1))
	$(GOMETALINTER) ./pkg/... | grep -vE ${LINT_SUPPRESS} | sort ; exit $$(($${PIPESTATUS[1]}-1))
	$(GOMETALINTER) ./cmd/... | grep -vE ${LINT_SUPPRESS} | sort ; exit $$(($${PIPESTATUS[1]}-1))

test_fast::
	go test -timeout 2m -cover -parallel ${TESTPARALLELISM} ${PROJECT_PKGS}

test_all::
	PATH=$(PULUMI_ROOT)/bin:$(PATH) go test -cover -parallel ${TESTPARALLELISM} ./examples ./tests

.PHONY: publish
publish:
	$(call STEP_MESSAGE)
	./scripts/publish.sh

.PHONY: coverage
coverage:
	$(call STEP_MESSAGE)
	./scripts/cocover.sh

# The travis_* targets are entrypoints for CI.
.PHONY: travis_cron travis_push travis_pull_request travis_api
travis_cron: all coverage
travis_push: all publish
travis_pull_request: all
travis_api: all

