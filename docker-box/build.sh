#!/usr/bin/env bash

set -x

vagrant destroy --force
rm -rf .vagrant docker-*.box

DOCKER_VERSION=18.09.7

DOCKER_VERSION=${DOCKER_VERSION} vagrant up

vagrant package --output docker-${DOCKER_VERSION}.box

vagrant box add docker-${DOCKER_VERSION} docker-${DOCKER_VERSION}.box --force

vagrant destroy --force

rm -rf .vagrant docker-*.box