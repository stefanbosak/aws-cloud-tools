#!/bin/bash
#
# Wrapper for standalone installation of AWS cloud tools
#
# NOTEs:
# - user has to have root priviledges / sudo to execute standalone-install.sh
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

# set variables
source "${cwd}/setvariables.sh"

# create temporary directory as workspace
WORKSPACE_ROOT_DIR=${WORKSPACE_ROOT_DIR:-"$(mktemp -d)"}

# cleanup handler (tidy up workspace)
trap 'rm -vfr "${WORKSPACE_ROOT_DIR}" "${GITHUB_ENV_TAIL_FILE}"' EXIT

echo "Initializing workspace ${WORKSPACE_ROOT_DIR}..."

# create workspace directory
if [ ! -d "${WORKSPACE_ROOT_DIR}" ]; then
  mkdir -pv "${WORKSPACE_ROOT_DIR}"
fi

# go to workspace directory
pushd "${WORKSPACE_ROOT_DIR}"

bash_completion_dir="/usr/share/bash-completion/completions"

if [ ! -d "${bash_completion_dir}" ]; then
  mkdir -pv "${bash_completion_dir}"
fi

# uninstallation
if [ "${1}" == "-u" ]; then
  # list of applications supported by this standalone-install script
  declare -a applications_array=("aws" "aws_completer" "sam" "helm" "kops" "kubectl" "terraform" "terragrunt")

  echo "Removing applications installed by ${cwd}/${0}..."

  for application in "${applications_array[@]}"; do
    # search for application and make sure not removing variant installed by default system package utility
    application_path="$(which ${application} | grep local)"

    if [ ! -z "${application_path}" ]; then
      if [ -f "${application_path}" ]; then
        rm -vf "${application_path}"
      fi
    fi

    application_completion_path="${bash_completion_dir}/${application}"

    if [ -f "${application_completion_path}" ]; then
      echo "Removing completion for ${application}"
      rm -vf "${application_completion_path}"
    fi
  done

  rm -vfr "/usr/local/aws-cli" "/usr/local/aws-sam-cli"
  echo "Removing has been finnished."
  exit 0
fi

# install required packages
declare -a tools_array=("curl" "dialog" "unzip")

for tool in "${tools_array[@]}"; do
  if [ -z "$(which ${tool})" ]; then
    echo -ne "Installing ${tool}..."

    if [ -f "/etc/debian_version" ]; then
      LINUX_DISTRIBUTION="ubuntu"
      PACKAGE_MANAGER_SUFFIX="deb"
      PACKAGE_MANAGER_CMD="dpkg -i"
      apt-get -y --no-install-recommends install "${tool}"
    elif [ -f "/etc/redhat-release" ]; then
      LINUX_DISTRIBUTION="linux"
      PACKAGE_MANAGER_SUFFIX="rpm"
      PACKAGE_MANAGER_CMD="rpm -i"
      rpm --nosuggest install unzip
    elif [ -f "/etc/centos-release" ]; then
      LINUX_DISTRIBUTION="linux"
      PACKAGE_MANAGER_SUFFIX="rpm"
      PACKAGE_MANAGER_CMD="yum localinstall"
      yum install "${tool}"
    fi

    if [ -z "$(which ${tool})" ]; then
      echo "Installation of ${tool} has failed (check details in your system), terminating..."
      exit 1
    fi
  fi
done

# handle downloading of AWS resources specificly due to AWS inconsistent naming of architectures
AWS_CLI_URI=$(echo "https://awscli.amazonaws.com/awscli-exe-${TARGETOS}-${TARGETARCH}-${AWS_CLI_VERSION}.zip" | sed -e 's/amd64/x86_64/g' -e 's/arm64/aarch64/g')
AWS_SAM_CLI_URI=$(echo "https://github.com/aws/aws-sam-cli/releases/download/${AWS_SAM_CLI_VERSION}/aws-sam-cli-${TARGETOS}-${TARGETARCH}.zip" | sed 's/amd64/x86_64/g')
AWS_SESSION_MANAGER_PLUGIN_URI=$(echo "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/${LINUX_DISTRIBUTION}_${TARGETARCH}/session-manager-plugin.${PACKAGE_MANAGER_SUFFIX}" | sed -e 's/amd64/64bit/g')

# dictionary of resources for download
declare -A resources_dictionary

resources_dictionary["awscli"]="${AWS_CLI_URI}"
resources_dictionary["aws-sam-cli"]="${AWS_SAM_CLI_URI}"
resources_dictionary["session-manager-plugin"]="${AWS_SESSION_MANAGER_PLUGIN_URI}"
resources_dictionary["helm"]="https://get.helm.sh/helm-${HELM_CLI_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz"
resources_dictionary["k9s"]="https://github.com/derailed/k9s/releases/download/${K9S_CLI_VERSION}/k9s_Linux_${TARGETARCH}.tar.gz"
resources_dictionary["kops"]="https://github.com/kubernetes/kops/releases/download/${KOPS_CLI_VERSION}/kops-${TARGETOS}-${TARGETARCH}"
resources_dictionary["kubectl"]="https://dl.k8s.io/release/${KUBECTL_CLI_VERSION}/bin/linux/${TARGETARCH}/kubectl"
resources_dictionary["terraform"]="https://releases.hashicorp.com/terraform/${TERRAFORM_CLI_VERSION}/terraform_${TERRAFORM_CLI_VERSION}_${TARGETOS}_${TARGETARCH}.zip"
resources_dictionary["terragrunt"]="https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_CLI_VERSION}/terragrunt_${TARGETOS}_${TARGETARCH}"
resources_dictionary["sam_completion"]="https://raw.githubusercontent.com/demotodo/sam_completion/master/sam_completion"

## now loop through the above dictionary items
for key in "${!resources_dictionary[@]}"; do
  echo -ne "Downloading [${key}]( ${resources_dictionary[$key]} )..."

  if [[ "${key}" =~ "aws" ]]; then
    # handle downloading of AWS resources specificly due to AWS inconsistent naming of architectures
    curl -sLJS "${resources_dictionary[$key]}" -o "${key}".zip
  else
    curl -sLJSO "${resources_dictionary[$key]}"
  fi

  if [ ${?} -eq 0 ]; then
    echo "[OK]"
  else
    echo "[FAIL]"
    exit 1
  fi
done

# install AWS CLI
echo "Installing AWS CLI..."
mkdir -v "${WORKSPACE_ROOT_DIR}/awscli" && unzip "awscli.zip" -d "${WORKSPACE_ROOT_DIR}/awscli"
"${WORKSPACE_ROOT_DIR}/awscli/aws/install" --update --install-dir "/usr/local/aws-cli" --bin-dir "/usr/local/bin"

if [ ${?} -eq 0 ]; then
  echo "Tool awscli has been installed successfully"
else
  echo "Tool awscli has not been installed, terminating"
  exit 1
fi

# install AWS session manager plugin
echo "Installing AWS session manager plugin..."
${PACKAGE_MANAGER_CMD} "session-manager-plugin.${PACKAGE_MANAGER_SUFFIX}"

if [ ${?} -eq 0 ]; then
  echo "Tool aws session manager plugin has been installed successfully"
else
  echo "Tool aws session manager plugin has not been installed, terminating"
  exit 1
fi

# install AWS SAM CLI
echo "Installing AWS SAM CLI..."
mkdir -v "${WORKSPACE_ROOT_DIR}/aws-sam-cli" && unzip "aws-sam-cli.zip" -d "${WORKSPACE_ROOT_DIR}/aws-sam-cli"
"${WORKSPACE_ROOT_DIR}/aws-sam-cli/install" --update --install-dir "/usr/local/aws-sam-cli" --bin-dir "/usr/local/bin"

if [ ${?} -eq 0 ]; then
  echo "Tool aws-sam-cli has been installed successfully"
else
  echo "Tool aws-sam-cli has not been installed, terminating"
  exit 1
fi

# install HELM
echo "Installing HELM CLI..."
tar -zxf "helm-${HELM_CLI_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz" -C "/usr/local/bin" --strip-components 1 --no-anchored "helm"

if [ ${?} -eq 0 ]; then
  echo "Tool helm has been installed successfully"
else
  echo "Tool helm has not been installed, terminating"
  exit 1
fi

# install kops
echo "Installing kops CLI..."
bash -c "install -v -o root -g root -m 0755 ${WORKSPACE_ROOT_DIR}/kops-${TARGETOS}-${TARGETARCH} /usr/local/bin/kops"

if [ ${?} -eq 0 ]; then
  echo "Tool kops has been installed successfully"
else
  echo "Tool kops has not been installed, terminating"
  exit 1
fi

# install kubectl
echo "Installing kubectl CLI..."
bash -c "install -v -o root -g root -m 0755 ${WORKSPACE_ROOT_DIR}/kubectl /usr/local/bin/"

if [ ${?} -eq 0 ]; then
  echo "Tool kubectl has been installed successfully"
else
  echo "Tool kubectl has not been installed, terminating"
  exit 1
fi

# install k9s
echo "Installing k9s CLI..."
tar -zxf "k9s_Linux_${TARGETARCH}.tar.gz" -C "/usr/local/bin" --no-anchored "k9s"

if [ ${?} -eq 0 ]; then
  echo "Tool k9s has been installed successfully"
else
  echo "Tool k9s has not been installed, terminating"
  exit 1
fi

# install TF CLI
echo "Installing terraform..."
unzip -o "terraform_${TERRAFORM_CLI_VERSION}_${TARGETOS}_${TARGETARCH}.zip" -d "/usr/local/bin/"

if [ ${?} -eq 0 ]; then
  echo "Tool terraform has been installed successfully"
else
  echo "Tool terraform has not been installed, terminating"
  exit 1
fi

# install Terragrunt CLI
echo "Installing terragrunt..."
bash -c "install -v -o root -g root -m 0755 ${WORKSPACE_ROOT_DIR}/terragrunt_${TARGETOS}_${TARGETARCH} /usr/local/bin/terragrunt"

if [ ${?} -eq 0 ]; then
  echo "Tool terragrunt has been installed successfully"
else
  echo "Tool terragrunt has not been installed, terminating"
  exit 1
fi

echo "Enabling completion for AWS CLI..."
bash -c "echo 'complete -C aws_completer aws' > ${bash_completion_dir}/aws"

echo "Enabling completion for AWS SAM CLI..."
bash -c "mv ${WORKSPACE_ROOT_DIR}/sam_completion ${bash_completion_dir}/sam"

echo "Enabling completion for HELM CLI..."
bash -c "helm completion bash > ${bash_completion_dir}/helm"

echo "Enabling completion for kops CLI..."
bash -c "kops completion bash > ${bash_completion_dir}/kops"

echo "Enabling completion for kubectl CLI..."
bash -c "kubectl completion bash > ${bash_completion_dir}/kubectl"

echo "Enabling completion for k9s CLI..."
bash -c "k9s completion bash > ${bash_completion_dir}/k9s"

echo "Enabling completion for terraform..."
bash -c "echo 'complete -C terraform terraform' > ${bash_completion_dir}/terraform"

echo "Enabling completion for terragrunt..."
bash -c "echo 'complete -C terragrunt terragrunt' > ${bash_completion_dir}/terragrunt"

popd
