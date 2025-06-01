#!/bin/bash
#
# Wrapper to build docker container
#
# NOTEs:
# - any execution and modification(s) is only in responsibility of user
# - use setvariables.sh for configuring versions and other variables
# - modify/align to fit user needs/requirements at your own
#
cwd=$(dirname $(realpath "${0}"))

# directory for storing capture of pushed versions
PUSHED_CLI_VERSIONS_FILE_DIR=$(mktemp -d)

# set variables
source "${cwd}/setvariables.sh"

# check if previous environment file exists and remove
if [ -f "${GITHUB_ENV_TAIL_FILE}" ]; then
  rm -f "${GITHUB_ENV_TAIL_FILE}"
fi

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

# build docker image
docker buildx build --network=host --force-rm --rm \
                    --platform ${TARGETPLATFORM} \
                    --build-arg TARGETOS=${TARGETOS} \
                    --build-arg ANSIBLE_CLI_VERSION=${ANSIBLE_CLI_VERSION} \
                    --build-arg AWS_CLI_VERSION=${AWS_CLI_VERSION} \
                    --build-arg AWS_SAM_CLI_VERSION=${AWS_SAM_CLI_VERSION} \
                    --build-arg HELM_CLI_VERSION=${HELM_CLI_VERSION} \
                    --build-arg KOPS_CLI_VERSION=${KOPS_CLI_VERSION} \
                    --build-arg KUBECTL_CLI_VERSION=${KUBECTL_CLI_VERSION} \
                    --build-arg K9S_CLI_VERSION=${K9S_CLI_VERSION} \
                    --build-arg TERRAFORM_CLI_VERSION=${TERRAFORM_CLI_VERSION} \
                    --build-arg TERRAGRUNT_CLI_VERSION=${TERRAGRUNT_CLI_VERSION} \
                    --build-arg WORKSPACE_ROOT_DIR=${WORKSPACE_ROOT_DIR} \
                    --build-arg CONTAINER_USER=${CONTAINER_USER} \
                    --build-arg CONTAINER_GROUP=${CONTAINER_GROUP} \
                    -t "${CONTAINER_IMAGE_NAME}${CONTAINER_IMAGE_TAG}" \
                    -f "${cwd}/Dockerfile" "${cwd}"

# clean temporary stage images
# - regexp in container image filters are still not supported in Docker
docker image prune -f --filter "label=stage=${CONTAINER_IMAGE_NAME}-image"
