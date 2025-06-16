ENV ?= git.kareem.one/kareem/blog
TAG ?= $(shell date +%Y%m%d%H%M)

.PHONY: docker push docker-base push-base

build:
	hugo --minify --gc --enableGitInfo --cleanDestinationDir

docker:
	docker build -t $(ENV):$(TAG) .

push:
	docker push $(ENV):$(TAG)
	docker tag $(ENV):$(TAG) $(ENV):latest
	docker push $(ENV):latest

docker-base:
	docker build -f Dockerfile.base -t $(ENV):base .

push-base:
	docker push $(ENV):base
