NAME := $(or ,$(NAME),seleniarm)
CURRENT_DATE := $(shell date '+%Y%m%d')
BUILD_DATE := $(or $(BUILD_DATE),$(CURRENT_DATE))
VERSION := $(or $(VERSION),4.0.0-beta-3)
TAG_VERSION := $(VERSION)-$(BUILD_DATE)
NAMESPACE := $(or $(NAMESPACE),$(NAME))
AUTHORS := $(or $(AUTHORS),sj26)
PUSH_IMAGE := $(or $(PUSH_IMAGE),false)
DEFAULT_BUILD_ARGS := --platform linux/arm64 --load
BUILD_ARGS := $(or $(BUILD_ARGS),$(DEFAULT_BUILD_ARGS))
MAJOR := $(word 1,$(subst ., ,$(TAG_VERSION)))
MINOR := $(word 2,$(subst ., ,$(TAG_VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(TAG_VERSION)))

all: \
	chromium \
  firefox \
  standalone_chromium \
  standalone_firefox

generate_all:	\
	generate_node_base \
	generate_chromium \
	generate_firefox \
	generate_standalone_firefox \
	generate_standalone_chromium

build: all

ci: build test

docker-setup:
	docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
	docker buildx create --name multiarch --driver docker-container --use
	docker buildx inspect --bootstrap

base: docker-setup
	cd ./Base && docker buildx build $(BUILD_ARGS) -t $(NAME)/base:$(TAG_VERSION) .

generate_node_base:
	cd ./NodeBase && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

node_base: base generate_node_base
	cd ./NodeBase && docker buildx build $(BUILD_ARGS) -t $(NAME)/node-base:$(TAG_VERSION) .

generate_chromium:
	cd ./NodeChromium && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

chromium: node_base generate_chromium
	cd ./NodeChromium && docker buildx build $(BUILD_ARGS) -t $(NAME)/node-chromium:$(TAG_VERSION) .

generate_firefox:
	cd ./NodeFirefox && ./generate.sh $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

firefox: node_base generate_firefox
	cd ./NodeFirefox && docker buildx build $(BUILD_ARGS) -t $(NAME)/node-firefox:$(TAG_VERSION) .

generate_standalone_firefox:
	cd ./Standalone && ./generate.sh StandaloneFirefox node-firefox $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

standalone_firefox: firefox generate_standalone_firefox
	cd ./StandaloneFirefox && docker buildx build $(BUILD_ARGS) -t $(NAME)/standalone-firefox:$(TAG_VERSION) .

generate_standalone_chromium:
	cd ./Standalone && ./generate.sh StandaloneChromium node-chromium $(TAG_VERSION) $(NAMESPACE) $(AUTHORS)

standalone_chromium: chromium generate_standalone_chromium
	cd ./StandaloneChromium && docker buildx build $(BUILD_ARGS) -t $(NAME)/standalone-chromium:$(TAG_VERSION) .

tag_latest:
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:latest
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:latest
	docker tag $(NAME)/node-chromium:$(TAG_VERSION) $(NAME)/node-chromium:latest
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:latest
	docker tag $(NAME)/standalone-chromium:$(TAG_VERSION) $(NAME)/standalone-chromium:latest
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:latest

tag_major_minor:
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:$(MAJOR)
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:$(MAJOR)
	docker tag $(NAME)/node-chromium:$(TAG_VERSION) $(NAME)/node-chromium:$(MAJOR)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR)
	docker tag $(NAME)/standalone-chromium:$(TAG_VERSION) $(NAME)/standalone-chromium:$(MAJOR)
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:$(MAJOR)
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-chromium:$(TAG_VERSION) $(NAME)/node-chromium:$(MAJOR).$(MINOR)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-chromium:$(TAG_VERSION) $(NAME)/standalone-chromium:$(MAJOR).$(MINOR)
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:$(MAJOR).$(MINOR)
	docker tag $(NAME)/base:$(TAG_VERSION) $(NAME)/base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-base:$(TAG_VERSION) $(NAME)/node-base:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-chromium:$(TAG_VERSION) $(NAME)/node-chromium:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/node-firefox:$(TAG_VERSION) $(NAME)/node-firefox:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-chromium:$(TAG_VERSION) $(NAME)/standalone-chromium:$(MAJOR_MINOR_PATCH)
	docker tag $(NAME)/standalone-firefox:$(TAG_VERSION) $(NAME)/standalone-firefox:$(MAJOR_MINOR_PATCH)

test: test_chromium \
 test_firefox \
 test_chromium_standalone \
 test_firefox_standalone

test_chromium:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeChromium

test_chromium_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneChromium

test_firefox:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh NodeFirefox

test_firefox_standalone:
	VERSION=$(TAG_VERSION) NAMESPACE=$(NAMESPACE) ./tests/bootstrap.sh StandaloneFirefox

.PHONY: \
	all \
	base \
	build \
	ci \
	chromium \
	firefox \
	generate_all \
	generate_node_base \
	generate_chromium \
	generate_firefox \
	generate_standalone_chromium \
	generate_standalone_firefox \
	standalone_chromium \
	standalone_firefox \
	tag_latest \
	test \
	docker-setup
