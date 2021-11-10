NAME := $(or ,$(NAME),seleniarm)
CURRENT_DATE := $(shell date '+%Y%m%d')
BUILD_DATE := $(or $(BUILD_DATE),$(CURRENT_DATE))
VERSION := $(or $(VERSION),4.0.0-beta-3)
TAG_VERSION := $(VERSION)-$(BUILD_DATE)
NAMESPACE := $(or $(NAMESPACE),$(NAME))
AUTHORS := $(or $(AUTHORS),dadav)
DEFAULT_BUILD_ARGS := --platform linux/arm64 --load
BUILD_ARGS := $(or $(BUILD_ARGS),$(DEFAULT_BUILD_ARGS))
MAJOR := $(word 1,$(subst ., ,$(TAG_VERSION)))
MINOR := $(word 2,$(subst ., ,$(TAG_VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(TAG_VERSION)))

all: \
	chromium \
  firefox

build: all

ci: build

docker-setup:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx use multiarch || docker buildx create --name multiarch --driver docker-container --use
	docker buildx inspect --bootstrap

chromium: docker-setup
	docker buildx build $(BUILD_ARGS) -t $(NAME)/chromium:$(TAG_VERSION) -f Dockerfile.chromium .

firefox: docker-setup
	docker buildx build $(BUILD_ARGS) -t $(NAME)/firefox:$(TAG_VERSION) -f Dockerfile.firefox .

tag_latest:
	docker tag $(NAME)/chromium:$(TAG_VERSION) $(NAME)/chromium:latest
	docker tag $(NAME)/firefox:$(TAG_VERSION) $(NAME)/firefox:latest

tag_major_minor:
	docker tag $(NAME)/chromium:$(TAG_VERSION) $(NAME)/chromium:$(MAJOR)
	docker tag $(NAME)/firefox:$(TAG_VERSION) $(NAME)/firefox:$(MAJOR)
	docker tag $(NAME)/chromium:$(TAG_VERSION) $(NAME)/chromium:$(MAJOR).$(MINOR)
	docker tag $(NAME)/firefox:$(TAG_VERSION) $(NAME)/firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/chromium:$(TAG_VERSION) $(NAME)/chromium:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/firefox:$(TAG_VERSION) $(NAME)/firefox:$(MAJOR_MINOR_PATCH)

.PHONY: \
	all \
	build \
	ci \
	chromium \
	firefox \
	tag_latest \
	tag_major_minor \
	docker-setup
