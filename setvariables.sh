#!/bin/bash
#
# Configuration of versions and other variables
#
# changed: 2024-Jan-11
#
# NOTEs:
# - any execution and modification(s) is only in responsibility of user
# - add container volume mapping(s) based on user preference
# - modify/align to fit user needs/requirements at your own
# - if needed use environment variables with same naming
#   (following variables have default/pre-defined values
#    and can be overrided by environment variables)
#
cwd=$(dirname $(realpath "${0}"))

# GitHub Actions workflow environment tail file
export GITHUB_ENV_TAIL_FILE=${GITHUB_ENV_TAIL_FILE:-"/tmp/github_env_tail"}

# automatically recognize and set latest available tools versions
# (any tool version can be overrided via corresponding variable)
source "${cwd}/set_latest_versions_strings.sh"

# default target OS, architecture and platforms
export TARGETOS=${TARGETOS:-linux}
export TARGETARCH=${TARGETARCH:-amd64}
export TARGETPLATFORM=${TARGETPLATFORM:-"${TARGETOS}/${TARGETARCH}"}

# set location of workspace directory
# (temporary space within container image)
export WORKSPACE_ROOT_DIR=${WORKSPACE_ROOT_DIR:-"/tmp/workspace"}

# container user and group
export CONTAINER_USER=${CONTAINER_USER:-"user"}
export CONTAINER_GROUP=${CONTAINER_GROUP:-"user"}

# Docker container entities
export CONTAINER_NAME=${CONTAINER_NAME:-"aws-cloud-tools"}

# it is crutial to have ":" in the beginning of the string
export CONTAINER_TAG=${CONTAINER_TAG:-":initial"}

# it is crutial to have "/" at the end of the string
export CONTAINER_REPOSITORY=${CONTAINER_REPOSITORY:-""}

export CONTAINER_IMAGE=${CONTAINER_IMAGE:-"${CONTAINER_REPOSITORY}${CONTAINER_NAME}${CONTAINER_TAG}"}

# AWS CLI tools versions
export AWS_CLI_VERSION=${AWS_CLI_VERSION:-2.15.9}
export AWS_SAM_CLI_VERSION=${AWS_SAM_CLI_VERSION:-v1.107.0}

# Helm version
export HELM_VERSION=${HELM_VERSION:-v3.13.3}

# kubectl version
export KUBECTL_VERSION=${KUBECTL_VERSION:-v1.29.0}

# Terraform version
export TERRAFORM_VERSION=${TERRAFORM_VERSION:-1.6.6}

# Terragrunt version
export TERRAGRUNT_VERSION=${TERRAGRUNT_VERSION:-v0.54.15}

if [[ ! -f "${GITHUB_ENV_TAIL_FILE}" ]]; then
  echo "AWS_CLI_VERSION=${AWS_CLI_VERSION}" > "${GITHUB_ENV_TAIL_FILE}"
  echo "AWS_SAM_CLI_VERSION=${AWS_SAM_CLI_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "HELM_VERSION=${HELM_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "KUBECTL_VERSION=${KUBECTL_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "TERRAFORM_VERSION=${TERRAFORM_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "TERRAGRUNT_VERSION=${TERRAGRUNT_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
fi

# get VERSIONS_CHANGED_FLAG if has been found
VERSIONS_CHANGED_FLAG=$(awk -F"=" '/VERSIONS_CHANGED/{print $2}' "${GITHUB_ENV_TAIL_FILE}")

# remove VERSIONS_CHANGED if in place
sed -i "/VERSIONS_CHANGED/d" "${GITHUB_ENV_TAIL_FILE}"

# pushed versions capture details
PUSHED_VERSIONS_FILE_DIR=${PUSHED_VERSIONS_FILE_DIR:-"${cwd}"}
PUSHED_VERSIONS_FILE_NAME_PATH=${PUSHED_VERSIONS_FILE_NAME_PATH:-"${PUSHED_VERSIONS_FILE_DIR}/PUSHED_VERSIONS.txt"}

if [ -z "${VERSIONS_CHANGED_FLAG}" ]; then
  # versions have not changed
  VERSIONS_CHANGED_FLAG=0
fi

if [[ ! -f "${PUSHED_VERSIONS_FILE_NAME_PATH}" ]]; then
  touch "${PUSHED_VERSIONS_FILE_NAME_PATH}"
fi

# check if any versions are different (requested vs pushed) since last push
VERSIONS_CHANGED_DIFF=$(diff "${GITHUB_ENV_TAIL_FILE}" "${PUSHED_VERSIONS_FILE_NAME_PATH}")

if [ ! -z "${VERSIONS_CHANGED_DIFF}" ]; then
  # versions have changed
  VERSIONS_CHANGED_FLAG=1

  # store versions change in repository as snapshot
  cp -f "${GITHUB_ENV_TAIL_FILE}" "${PUSHED_VERSIONS_FILE_NAME_PATH}"

  if [ "${PUSHED_VERSIONS_FILE_DIR}"  == "${cwd}" ]; then
    export GIT_USER_NAME="GitHub Actions"
    export GIT_USER_EMAIL="<>"
    export GIT_COMMITTER_NAME="${GIT_USER_NAME}"
    export GIT_COMMITTER_EMAIL="${GIT_USER_EMAIL}"
    export GIT_AUTHOR_NAME="${GIT_USER_NAME}"
    export GIT_AUTHOR_EMAIL="${GIT_USER_EMAIL}"

    git diff -- "${PUSHED_VERSIONS_FILE_NAME_PATH}"
    git add "${PUSHED_VERSIONS_FILE_NAME_PATH}"
    git commit -o "${PUSHED_VERSIONS_FILE_NAME_PATH}" -m "Updated PUSHED_VERSIONS.txt"
  fi
fi

# set environment variable regarding VERSIONS_CHANGED
# (used in GitHub Actions workflow as condition variable for workflow steps)
echo "VERSIONS_CHANGED=${VERSIONS_CHANGED_FLAG}" >> "${GITHUB_ENV_TAIL_FILE}"
