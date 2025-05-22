.PHONY: build docker

# Image name can be overridden via `make docker ENV=my.registry/image`
ENV ?= git.kareem.one/kareem/blog
TAG := $(shell date +%Y%m%d%H%M)

build:
	hugo --minify --gc --enableGitInfo --cleanDestinationDir

docker:
	docker build -t $(ENV):$(TAG) .
