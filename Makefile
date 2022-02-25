SHELL = /usr/bin/env bash
export
.DEFAULT: help
INTERACTIVE:=$(shell [ -t 0 ] && echo 1)
ifdef INTERACTIVE
	ADD_COLOR ?= -it
endif
DEPLOY_ENV ?= NOT_SET
ARTIFACT_REPO_URL_FOR_PUSH ?= artifacts.flowcast.ai:8886
ARTIFACT_REPO_URL_FOR_PULL ?= artifacts.flowcast.ai:8888
K8S_EKS_REGION ?= us-west-2
K8S_CONTEXT ?= eks-till-dev-00
KUBECONFIG ?= $(HOME)/.kube/$(K8S_CONTEXT)
KUBESCAPE_IGNORED_NAMESPACES ?= --exclude-namespaces calico-system,$\
  cluster-autoscaler,fsx-cleaner,kube-node-lease,kube-public,kube-system,$\
  kubernetes-dashboard,monitoring,netdata,portainer,redash,tigera-operator,$\
  till-admin-develop,till-admin-master,traefik
KUBESCAPE_FRAMEWORKS=nsa,mitre,armobest,devopsbest
KUBESCAPE_SCAN_CMD ?= scan $\
	framework $(KUBESCAPE_FRAMEWORKS) $\
	--fail-threshold 3.0 $\
	--controls-config config.json $\
	$(KUBESCAPE_IGNORED_NAMESPACES) $\
	--exceptions exceptions.json
KUBESCAPE_VERSION ?= v1.0.137
IMAGE_NAME ?= kubescape:$(KUBESCAPE_VERSION)

help:
	open README.md

all: build kubeconfig run

setup:
	which aws && aws --version
	which docker && docker --version

build:
	docker build \
		--build-arg KUBESCAPE_VERSION=$(KUBESCAPE_VERSION) \
		-t $(ARTIFACT_REPO_URL_FOR_PULL)/$(IMAGE_NAME) \
	.
	docker tag \
		$(ARTIFACT_REPO_URL_FOR_PULL)/$(IMAGE_NAME) \
		$(ARTIFACT_REPO_URL_FOR_PUSH)/kubescape:latest

login:
	docker login \
		-u $(ARTIFACTS_USERNAME) \
		-p $(ARTIFACTS_PASSWORD) \
	$(ARTIFACT_REPO_URL_FOR_PUSH)

push: login
	docker tag \
		$(ARTIFACT_REPO_URL_FOR_PULL)/$(IMAGE_NAME) \
		$(ARTIFACT_REPO_URL_FOR_PUSH)/$(IMAGE_NAME)
	docker push $(ARTIFACT_REPO_URL_FOR_PUSH)/$(IMAGE_NAME)
	docker push $(ARTIFACT_REPO_URL_FOR_PUSH)/kubescape:latest

pull:
	docker pull $(ARTIFACT_REPO_URL_FOR_PULL)/$(IMAGE_NAME)
	docker pull $(ARTIFACT_REPO_URL_FOR_PULL)/kubescape:latest

$(HOME)/.kube:
	mkdir -p $(HOME)/.kube

kubeconfig: $(HOME)/.kube
	aws eks \
		--region $(K8S_EKS_REGION) \
	update-kubeconfig \
		--name $(K8S_CONTEXT) \
		--alias $(K8S_CONTEXT) \
		--kubeconfig $(KUBECONFIG)

$(HOME)/.aws:
	mkdir -p $(HOME)/.aws

scan: $(HOME)/.aws
	docker run --rm $(ADD_COLOR) \
		-v $(KUBECONFIG):/root/.kube/config \
		-v $(HOME)/.aws:/root/.aws \
		-v $(PWD)/config.json:/root/.kubescape/config.json \
		-v $(PWD):/aws \
	$(ARTIFACT_REPO_URL_FOR_PULL)/$(IMAGE_NAME) \
	$(KUBESCAPE_SCAN_CMD)

install:
	curl -s https://raw.githubusercontent.com/armosec/kubescape/master/install.sh | bash

scan-local: $(HOME)/.aws
	kubescape $(KUBESCAPE_SCAN_CMD)

bash:
	docker run --rm -it \
		-v $(KUBECONFIG):/root/.kube/config \
		-v $(HOME)/.aws:/root/.aws \
		-v $(PWD)/config.json:/root/.kubescape/config.json \
		-v $(PWD):/aws \
		--entrypoint bash \
		$(ARTIFACT_REPO_URL_FOR_PULL)/$(IMAGE_NAME)

test-jenkinsfile:
	docker run --rm -v $(PWD):/home/groovy/app groovy:3.0.6 \
		bash -c "cd /home/groovy/app && \
		groovy -cp scripts/jenkinsfile scripts/jenkinsfile/Tests.groovy"

test-jenkinsfile-local:
	groovy -cp scripts/jenkinsfile scripts/jenkinsfile/Tests.groovy

printenv:
	env | sort
