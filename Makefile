SHELL = /usr/bin/env bash

.DEFAULT: help
DEPLOY_ENV ?= NOT_SET
ARTIFACT_REPO_URL_FOR_PUSH ?= artifacts.flowcast.ai:8886
ARTIFACT_REPO_URL_FOR_PULL ?= artifacts.flowcast.ai:8888
K8S_EKS_REGION ?= us-west-2
K8S_CONTEXT ?= eks-till-dev-00
KUBECONFIG ?= $(HOME)/.kube/$(K8S_CONTEXT)
KUBESCAPE_IGNORED_NAMESPACES ?= \
	cluster-autoscaler,fsx-cleaner,kube-node-lease,kube-public,kube-system,kubernetes-dashboard,monitoring,netdata,portainer,redash
KUBESCAPE_SCAN_ARGS ?= \
	--fail-threshold 100 \
	--exclude-namespaces $(KUBESCAPE_IGNORED_NAMESPACES) \
	--exceptions exceptions.json
KUBESCAPE_VERSION ?= v1.0.130
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

nsa: $(HOME)/.aws
	docker run --rm \
		-v $(KUBECONFIG):/root/.kube/config \
		-v $(HOME)/.aws:/root/.aws \
		-v $(PWD):/aws \
	$(ARTIFACT_REPO_URL_FOR_PULL)/$(IMAGE_NAME) \
	scan framework nsa \
	$(KUBESCAPE_SCAN_ARGS)

mitre: $(HOME)/.aws
	docker run --rm \
		-v $(KUBECONFIG):/root/.kube/config \
		-v $(HOME)/.aws:/root/.aws \
		-v $(PWD):/aws \
	$(ARTIFACT_REPO_URL_FOR_PULL)/$(IMAGE_NAME) \
	scan framework mitre \
	$(KUBESCAPE_SCAN_ARGS)

install:
	curl -s https://raw.githubusercontent.com/armosec/kubescape/master/install.sh | bash

nsa-local: $(HOME)/.aws
	kubescape scan framework nsa $(KUBESCAPE_SCAN_ARGS)

mitre-local: $(HOME)/.aws
	kubescape scan framework mitre $(KUBESCAPE_SCAN_ARGS)

bash:
	docker run --rm -it \
		--entrypoint bash \
		$(ARTIFACT_REPO_URL_FOR_PULL)/$(IMAGE_NAME)

test-jenkinsfile:
	docker run --rm -v $(PWD):/home/groovy/app groovy:3.0.6 \
		bash -c "cd /home/groovy/app && \
		groovy -cp scripts/jenkinsfile scripts/jenkinsfile/Tests.groovy"

test-jenkinsfile-local:
	groovy -cp scripts/jenkinsfile scripts/jenkinsfile/Tests.groovy
