#!/bin/bash
#
# Wrapper to push docker container image into user configured container registry
#
# NOTEs:
# - any execution and modification(s) is only in responsibility of user
# - use setvariables.sh for configuring versions and other variables
# - modify/align to fit user needs/requirements at your own
#
cwd=$(dirname $(realpath "${0}"))

# directory for storing capture of pushed versions
PUSHED_CLI_VERSIONS_FILE_DIR=$(mktemp -d)

# cleanup
trap 'rm -fr "${PUSHED_CLI_VERSIONS_FILE_DIR}"' EXIT

# set variables
source "${cwd}/setvariables.sh"

# check prerequisites (if all required tools are available)
TOOLS="docker"

for tool in ${TOOLS}; do
  if [ -z "$(which ${tool})" ]; then
    echo "Tool ${tool} has not been found, please install tool in your system"
    exit 1
  fi
done

if [ -z "${CONTAINER_REPOSITORY}" ]; then
  echo "Remote container registry repository has not be set in variable CONTAINER_REPOSITORY (see ${cwd}/setvariables.sh)"
  exit 1
fi

# source image (local build)
CONTAINER_SOURCE_IMAGE="${CONTAINER_IMAGE_NAME}${CONTAINER_IMAGE_TAG}"

# destination image (remote container repository)
CONTAINER_TARGET_IMAGE="${CONTAINER_REPOSITORY}${CONTAINER_IMAGE_NAME}${CONTAINER_IMAGE_TAG}"

# login to DockerHub (GitHub package is using GitHub token)
#docker login

# tag container image before uploading
docker image tag "${CONTAINER_SOURCE_IMAGE}" "${CONTAINER_TARGET_IMAGE}"

# upload container image to remote container registry
docker image push "${CONTAINER_TARGET_IMAGE}"
