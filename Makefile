NAME := dadav
VERSION := $(or $(VERSION),4.0.0-beta-3)
TAG_VERSION := $(VERSION)
NAMESPACE := $(or $(NAMESPACE),$(NAME))
AUTHORS := $(or $(AUTHORS),dadav)
DEFAULT_BUILD_ARGS := --platform linux/arm64 $(if $(PUSH),--push,--load)
BUILD_ARGS := $(or $(BUILD_ARGS),$(DEFAULT_BUILD_ARGS))
MAJOR := $(word 1,$(subst ., ,$(TAG_VERSION)))
MINOR := $(word 2,$(subst ., ,$(TAG_VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(TAG_VERSION)))

all: \
	chromium \
  firefox \
	chorium-nginx

build: all

ci: build

test: test_chromium test_firefox

test_chromium:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh chromium

test_firefox:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh firefox

docker-setup:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx use multiarch || docker buildx create --name multiarch --driver docker-container --use
	docker buildx inspect --bootstrap

chromium: docker-setup
	docker buildx build $(BUILD_ARGS) -t $(NAME)/seleniarm-chromium:$(TAG_VERSION) -f Dockerfile.chromium .

chromium-nginx: docker-setup
	docker buildx build $(BUILD_ARGS) -t $(NAME)/seleniarm-chromium-nginx:$(TAG_VERSION) -f Dockerfile.chromium.nginx .

firefox: docker-setup
	docker buildx build $(BUILD_ARGS) -t $(NAME)/seleniam-firefox:$(TAG_VERSION) -f Dockerfile.firefox .

tag_latest:
	docker tag $(NAME)/seleniarm-chromium:$(TAG_VERSION) $(NAME)/seleniarm-chromium:latest
	docker tag $(NAME)/seleniarm-firefox:$(TAG_VERSION) $(NAME)/seleniarm-firefox:latest

tag_major_minor:
	docker tag $(NAME)/seleniarm-chromium:$(TAG_VERSION) $(NAME)/seleniarm-chromium:$(MAJOR)
	docker tag $(NAME)/seleniarm-firefox:$(TAG_VERSION) $(NAME)/seleniarm-firefox:$(MAJOR)
	docker tag $(NAME)/seleniarm-chromium:$(TAG_VERSION) $(NAME)/seleniarm-chromium:$(MAJOR).$(MINOR)
	docker tag $(NAME)/seleniarm-firefox:$(TAG_VERSION) $(NAME)/seleniarm-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/seleniarm-chromium:$(TAG_VERSION) $(NAME)/seleniarm-chromium:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/seleniarm-firefox:$(TAG_VERSION) $(NAME)/seleniarm-firefox:$(MAJOR_MINOR_PATCH)

.PHONY: \
	all \
	build \
	ci \
	test \
	test_firefox \
	test_chromium \
	chromium \
	chromium-nginx \
	firefox \
	tag_latest \
	tag_major_minor \
	docker-setup
