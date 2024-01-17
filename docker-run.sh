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
  docker container run --platform ${TARGETPLATFORM} -ti -v /dev:/dev --network=host --rm --name "${CONTAINER_NAME}" "${CONTAINER_IMAGE}"
else
  # when any argument recognized only execute requested application/command inside container (oneshot action)
  docker container run --platform ${TARGETPLATFORM} --entrypoint "/bin/sh" --network=host --rm --name "${CONTAINER_NAME}" "${CONTAINER_IMAGE}" -c "${*}"
fi

if [ ${?} -ne 0 ]; then
  echo -e "\nCheck docker please.\n" \
          "It seems that container image ${CONTAINER_IMAGE} not found:\n" \
          " probably not executed ${cwd}/docker-build.sh or\n" \
          " not set remote container registry using variable \n" \
          " CONTAINER_REPOSITORY via ${cwd}/setvariables.sh"
  exit 1
fi
