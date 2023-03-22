user=meshcloud
name=gate-resource
image=$(user)/$(name)
tag=$(shell git log --format="%h" -n 1)

docker=docker
dockerfile = Dockerfile

build:
	$(docker) build -t $(image):$(tag) -f $(dockerfile) .

push: build
	$(docker) push $(image):$(tag)
	$(docker) tag $(image):$(tag) $(image):latest
	$(docker) push $(image):latest
