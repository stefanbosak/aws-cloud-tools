#!/bin/bash
#
# Wrapper to run docker container
#
# NOTEs:
# - any execution and modification(s) is only in responsibility of user
# - use setvariables.sh for configuring versions and other variables
# - add container volume mapping(s) based on user preference
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

if [ ${#} -eq 0 ]; then
  # when no argument(s) provided just use container as AWS cloud ecosystem/environment accessor containing necessary tools
  docker container run --platform ${TARGETPLATFORM} -ti -v /dev:/dev --privileged \
                       -v "${cwd}/.docker":"/home/${CONTAINER_USER}/.docker" \
                       --network=host --rm --name "${CONTAINER_NAME}" \
                       --group-add "docker" \
                       "${CONTAINER_REPOSITORY}${CONTAINER_IMAGE_NAME}${CONTAINER_IMAGE_TAG}"
else
  # when any argument recognized only execute requested application/command inside container (oneshot action)
  docker container run --platform ${TARGETPLATFORM} --privileged --entrypoint "/bin/sh" \
                       -v "${cwd}/.docker":"/home/${CONTAINER_USER}/.docker" \
                       --network=host --rm --name "${CONTAINER_NAME}" \
                       --group-add "docker" \
                       "${CONTAINER_REPOSITORY}${CONTAINER_IMAGE_NAME}${CONTAINER_IMAGE_TAG}" \
                       -c "${*}"
fi
