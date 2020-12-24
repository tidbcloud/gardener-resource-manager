# Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

REGISTRY                    := gcr.io/pingcap-public
IMAGE_PREFIX                := $(REGISTRY)/gardener
REPO_ROOT                   := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
HACK_DIR                    := $(REPO_ROOT)/hack
VERSION                     := $(shell cat VERSION)
LD_FLAGS                    := "-w -X github.com/gardener/gardener-resource-manager/pkg/version.Version=$(IMAGE_TAG)"
VERIFY                      := true

### Build commands

.PHONY: format
format:
	@./hack/format.sh

.PHONY: clean
clean:
	@./hack/clean.sh

.PHONY: generate
generate:
	@./hack/generate.sh

.PHONY: check
check:
	@./hack/check.sh

.PHONY: test
test:
	@./hack/test.sh

.PHONY: verify
verify: check generate test format

.PHONY: install
install:
	@./hack/install.sh

.PHONY: all
ifeq ($(VERIFY),true)
all: verify generate install
else
all: generate install
endif

### Docker commands

.PHONY: docker-login
docker-login:
	@gcloud auth activate-service-account --key-file .kube-secrets/gcr/gcr-readwrite.json

.PHONY: docker-image
docker-image:
	@docker build --build-arg VERIFY=$(VERIFY) -t $(IMAGE_PREFIX)/gardener-resource-manager:$(VERSION) -t $(IMAGE_PREFIX)/gardener-resource-manager:latest -f Dockerfile --target gardener-resource-manager .

### Debug / Development commands

.PHONY: revendor
revendor:
	@GO111MODULE=on go mod vendor
	@GO111MODULE=on go mod tidy

.PHONY: start
start:
	@GO111MODULE=on go run \
	    -mod=vendor \
		-ldflags $(LD_FLAGS) \
		./cmd/gardener-resource-manager \
	  --leader-election=false \
	  --sync-period=60s \
	  --max-concurrent-workers=10 \
	  --health-sync-period=60s \
	  --health-max-concurrent-workers=10
