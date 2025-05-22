ENV ?= git.kareem.one/kareem/blog
TAG := $(shell date +%Y%m%d%H%M)

.PHONY: docker push

build:
	hugo --minify --gc --enableGitInfo --cleanDestinationDir

docker:
	docker build -t $(ENV):$(TAG) .

push:
	docker push $(ENV):$(TAG)
	docker tag $(ENV):$(TAG) $(ENV):latest
	docker push $(ENV):latest
