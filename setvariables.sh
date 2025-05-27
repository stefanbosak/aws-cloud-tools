#!/bin/bash
#
# Configuration of versions and other variables
#
# changed: 2025-Apr-23
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

# Ubuntu releases URI
export UBUNTU_RELEASES_URI="https://changelogs.ubuntu.com/meta-release"

# Ubuntu LTS releases URI (comment if prefer non-LTS)
export UBUNTU_RELEASES_URI="${UBUNTU_RELEASES_URI}-lts"

# extract last supported Ubuntu LTS release
export UBUNTU_RELEASE=$(curl -s "${UBUNTU_RELEASES_URI}" | awk '/^Version:/ {if ($2 ~ /^[0-9]{2}\.[0-9]{2}\./) version=substr($2, 1, 5)} /^Supported: 1/ {if (version) print version}' | tail -n 1)

# default target OS, architecture and platforms
export TARGETOS=${TARGETOS:-linux}
export TARGETARCH=${TARGETARCH:-$(dpkg --print-architecture)}
export TARGETPLATFORM=${TARGETPLATFORM:-"${TARGETOS}/${TARGETARCH}"}

# set location of workspace directory
# (temporary space within container image)
export WORKSPACE_ROOT_DIR=${WORKSPACE_ROOT_DIR:-"/tmp/workspace"}

# container user and group
export CONTAINER_USER=${CONTAINER_USER:-"user"}
export CONTAINER_GROUP=${CONTAINER_GROUP:-"user"}

# container name
export CONTAINER_NAME=${CONTAINER_NAME:-"aws-cloud-tools"}

# container image name
export CONTAINER_IMAGE_NAME=${CONTAINER_IMAGE_NAME:-"aws-cloud-tools"}

# it is crutial to have ":" in the beginning of the string
export CONTAINER_IMAGE_TAG=${CONTAINER_TAG:-":initial"}

# it is crutial to have "/" at the end of the string
export CONTAINER_REPOSITORY=${CONTAINER_REPOSITORY:-""}

# docker compose settings
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1
export DOCKER_DEFAULT_PLATFORM="${TARGETPLATFORM}"

# ansible CLI tool version
export ANSIBLE_CLI_VERSION=${ANSIBLE_CLI_VERSION:-2.19.0b4}

# AWS CLI tools versions
export AWS_CLI_VERSION=${AWS_CLI_VERSION:-2.27.12}
export AWS_SAM_CLI_VERSION=${AWS_SAM_CLI_VERSION:-v1.139.0}

# Helm version
export HELM_CLI_VERSION=${HELM_CLI_VERSION:-v3.18.0}

# k9s version
export K9S_CLI_VERSION=${K9S_CLI_VERSION:-v0.50.6}

# kops version
export KOPS_CLI_VERSION=${KOPSL_CLI_VERSION:-v1.32.0}

# kubectl version
export KUBECTL_CLI_VERSION=${KUBECTL_CLI_VERSION:-v1.33.1}

# Terraform version
export TERRAFORM_CLI_VERSION=${TERRAFORM_CLI_VERSION:-1.12.1}

# Terragrunt version
export TERRAGRUNT_CLI_VERSION=${TERRAGRUNT_CLI_VERSION:-v0.80.2}

if [[ ! -f "${GITHUB_ENV_TAIL_FILE}" ]]; then
  echo "ANSIBLE_CLI_VERSION=${ANSIBLE_CLI_VERSION}" > "${GITHUB_ENV_TAIL_FILE}"
  echo "AWS_CLI_VERSION=${AWS_CLI_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "AWS_SAM_CLI_VERSION=${AWS_SAM_CLI_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "HELM_CLI_VERSION=${HELM_CLI_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "K9S_CLI_VERSION=${K9S_CLI_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "KOPS_CLI_VERSION=${KOPS_CLI_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "KUBECTL_CLI_VERSION=${KUBECTL_CLI_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "TERRAFORM_CLI_VERSION=${TERRAFORM_CLI_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
  echo "TERRAGRUNT_CLI_VERSION=${TERRAGRUNT_CLI_VERSION}" >> "${GITHUB_ENV_TAIL_FILE}"
fi

# get CLI_VERSIONS_CHANGED_FLAG if has been found
CLI_VERSIONS_CHANGED_FLAG=$(awk -F"=" '/CLI_VERSIONS_CHANGED/{print $2}' "${GITHUB_ENV_TAIL_FILE}")

# remove CLI_VERSIONS_CHANGED if in place
sed -i "/CLI_VERSIONS_CHANGED/d" "${GITHUB_ENV_TAIL_FILE}"

# pushed versions capture details
PUSHED_CLI_VERSIONS_FILE_DIR=${PUSHED_CLI_VERSIONS_FILE_DIR:-"${cwd}"}
PUSHED_CLI_VERSIONS_FILE_NAME_PATH=${PUSHED_CLI_VERSIONS_FILE_NAME_PATH:-"${PUSHED_CLI_VERSIONS_FILE_DIR}/PUSHED_CLI_VERSIONS.txt"}

if [ -z "${CLI_VERSIONS_CHANGED_FLAG}" ]; then
  # versions have not changed
  CLI_VERSIONS_CHANGED_FLAG=0
fi

if [[ ! -f "${PUSHED_CLI_VERSIONS_FILE_NAME_PATH}" ]]; then
  touch "${PUSHED_CLI_VERSIONS_FILE_NAME_PATH}"
fi

# check if any versions are different (requested vs pushed) since last push
CLI_VERSIONS_CHANGED_DIFF=$(diff "${GITHUB_ENV_TAIL_FILE}" "${PUSHED_CLI_VERSIONS_FILE_NAME_PATH}")

if [ ! -z "${CLI_VERSIONS_CHANGED_DIFF}" ]; then
  # versions have changed
  CLI_VERSIONS_CHANGED_FLAG=1

  # store versions change in repository as snapshot
  cp -f "${GITHUB_ENV_TAIL_FILE}" "${PUSHED_CLI_VERSIONS_FILE_NAME_PATH}"

  if [ "${PUSHED_CLI_VERSIONS_FILE_DIR}"  == "${cwd}" ]; then
    export GIT_USER_NAME="GitHub Actions"
    export GIT_USER_EMAIL="<>"
    export GIT_COMMITTER_NAME="${GIT_USER_NAME}"
    export GIT_COMMITTER_EMAIL="${GIT_USER_EMAIL}"
    export GIT_AUTHOR_NAME="${GIT_USER_NAME}"
    export GIT_AUTHOR_EMAIL="${GIT_USER_EMAIL}"

    git diff -- "${PUSHED_CLI_VERSIONS_FILE_NAME_PATH}"
    git add "${PUSHED_CLI_VERSIONS_FILE_NAME_PATH}"
    git commit -o "${PUSHED_CLI_VERSIONS_FILE_NAME_PATH}" -m "Updated PUSHED_CLI_VERSIONS.txt"
    git pull --rebase
  fi
fi

# set environment variable regarding CLI_VERSIONS_CHANGED
# (used in GitHub Actions workflow as condition variable for workflow steps)
echo "CLI_VERSIONS_CHANGED=${CLI_VERSIONS_CHANGED_FLAG}" >> "${GITHUB_ENV_TAIL_FILE}"
