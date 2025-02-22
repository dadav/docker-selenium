import logging
import os
import random
import sys
import unittest

import docker
from docker.errors import NotFound

# LOGGING #
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Docker Client
client = docker.from_env()

NAMESPACE = os.environ.get('NAMESPACE')
VERSION = os.environ.get('VERSION')
USE_RANDOM_USER_ID = os.environ.get('USE_RANDOM_USER_ID')
RUN_IN_DOCKER_COMPOSE = os.environ.get('RUN_IN_DOCKER_COMPOSE')
http_proxy = os.environ.get('http_proxy', '')
https_proxy = os.environ.get('https_proxy', '')
no_proxy = os.environ.get('no_proxy', '')

TEST_NAME_MAP = {
    'chromium': 'ChromiumTests',
    'firefox': 'FirefoxTests',
}

def create_network(network_name):
    client.networks.create(network_name, driver="bridge")


def prune_networks():
    client.networks.prune()


def launch_container(container, **kwargs):
    """
    Launch a specific container
    :param container:
    :return: the container ID
    """
    # Build the container if it doesn't exist
    logger.info("Building %s container..." % container)
    client.images.build(path='../%s' % container,
                        tag="%s/%s:%s" % (NAMESPACE, container, VERSION),
                        rm=True)
    logger.info("Done building %s" % container)

    # Run the container
    logger.info("Running %s container..." % container)
    # Merging env vars
    environment = {
        'http_proxy': http_proxy,
        'https_proxy': https_proxy,
        'no_proxy': no_proxy,
        'SE_EVENT_BUS_HOST': 'selenium-hub',
        'SE_EVENT_BUS_PUBLISH_PORT': 4442,
        'SE_EVENT_BUS_SUBSCRIBE_PORT': 4443
    }
    container_id = client.containers.run("%s/%s:%s" % (NAMESPACE, container, VERSION),
                                         detach=True,
                                         environment=environment,
                                         shm_size="2G",
                                         **kwargs).short_id
    logger.info("%s up and running" % container)
    return container_id


if __name__ == '__main__':
    # The container to test against
    image = sys.argv[1]

    use_random_user_id = USE_RANDOM_USER_ID == 'true'
    random_user_id = random.randint(100000, 2147483647)

    if use_random_user_id:
        logger.info("Running tests with a random user ID -> %s" % random_user_id)

    # Flag for failure (for posterity)
    failed = False

    # Avoiding to start the containers when running inside docker-compose
    test_container_id = ''
    hub_id = ''

    logger.info('========== Starting %s Container ==========' % image)

    ports = {'4444': 4444}
    if use_random_user_id:
        test_container_id = launch_container(image, ports=ports, user=random_user_id)
    else:
        test_container_id = launch_container(image, ports=ports)

    logger.info('========== / Containers ready to go ==========')

    try:
        # Smoke tests
        logger.info('*********** Running smoke tests %s Tests **********' % image)
        image_class = "%sTest" % image
        module = __import__('SmokeTests', fromlist='GridTest')
        test_class = getattr(module, 'GridTest')
        suite = unittest.TestLoader().loadTestsFromTestCase(test_class)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e)
        failed = True

    try:
        # Run Selenium tests
        logger.info('*********** Running Selenium tests %s Tests **********' % image)
        test_class = getattr(__import__('SeleniumTests', fromlist=[TEST_NAME_MAP[image]]), TEST_NAME_MAP[image])
        suite = unittest.TestLoader().loadTestsFromTestCase(test_class)
        test_runner = unittest.TextTestRunner(verbosity=3)
        failed = not test_runner.run(suite).wasSuccessful()
    except Exception as e:
        logger.fatal(e)
        failed = True

    # Avoiding a container cleanup if tests run inside docker-compose
    logger.info("Cleaning up...")

    test_container = client.containers.get(test_container_id)
    test_container.kill()
    test_container.remove()

    logger.info("Standalone Cleaned up")

    if failed:
        exit(1)
