# set location of workspace directory
# (temporary space within container image)
ARG WORKSPACE_ROOT_DIR=/tmp/workspace

# user in container
ARG CONTAINER_USER=user
ARG CONTAINER_GROUP=user

# Debian release and options
ARG DEBIAN_RELEASE=testing-slim
ARG DEBIAN_FRONTEND=noninteractive

# AWS CLI tools versions
ARG AWS_CLI_VERSION=2.15.9
ARG AWS_SAM_CLI_VERSION=v1.107.0

# Helm version
ARG HELM_CLI_VERSION=v3.13.3

# kubectl version
ARG KUBECTL_CLI_VERSION=v1.29.0

# kops version
ARG KOPS_CLI_VERSION=v1.28.2

# Terraform version
ARG TERRAFORM_CLI_VERSION=1.6.6

# Terragrunt version
ARG TERRAGRUNT_CLI_VERSION=v0.54.15


# container as builder for preparing AWS cloud tools
FROM debian:${DEBIAN_RELEASE} AS aws-cloud-tools-builder

LABEL stage="aws-cloud-tools-builder" \
      description="Debian-based container builder for preparing AWS cloud tools"

ARG DEBIAN_FRONTEND

WORKDIR "${WORKSPACE_ROOT_DIR}"

# install required packages and additional applications
RUN apt-get update && \
    apt-get -y --no-install-recommends install ca-certificates binutils curl unzip && \
    apt-get clean && rm -rf "/var/lib/apt/lists/*"


# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-aws-cli-builder

LABEL stage="aws-cloud-tools-aws-cli-builder" \
      description="Debian-based container builder for preparing AWS cloud tool AWS CLI"

ARG TARGETOS
ARG TARGETARCH
ARG AWS_CLI_VERSION

ARG WORKSPACE_ROOT_DIR

WORKDIR "${WORKSPACE_ROOT_DIR}"

# download and install AWS CLI, AWS session-manager-plugin
RUN uri=$(echo "https://awscli.amazonaws.com/awscli-exe-${TARGETOS}-${TARGETARCH}-${AWS_CLI_VERSION}.zip" | sed -e 's/amd64/x86_64/g' -e 's/arm64/aarch64/g') && curl -sSL "${uri}" -o "awscli.zip" && \
    mkdir -v "${WORKSPACE_ROOT_DIR}/awscli" && unzip "awscli.zip" -d "${WORKSPACE_ROOT_DIR}/awscli" && \
    "${WORKSPACE_ROOT_DIR}/awscli/aws/install" --install-dir "/usr/local/aws-cli" --bin-dir "/usr/local/bin" && \
    uri=$(echo "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_${TARGETARCH}/session-manager-plugin.deb" | sed -e 's/amd64/64bit/g') && curl -sSLO "${uri}" && \
    ar x "${WORKSPACE_ROOT_DIR}/session-manager-plugin.deb" && \
    tar -xvf data.tar.gz -C "${WORKSPACE_ROOT_DIR}" && \
    mv "${WORKSPACE_ROOT_DIR}/usr/local/sessionmanagerplugin/bin/session-manager-plugin" "/usr/local/bin"

# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-aws-sam-cli-builder

LABEL stage="aws-cloud-tools-aws-sam-cli-builder" \
      description="Debian-based container builder for preparing AWS cloud tool AWS SAM CLI"

ARG TARGETOS
ARG TARGETARCH
ARG AWS_SAM_CLI_VERSION

ARG WORKSPACE_ROOT_DIR

WORKDIR "${WORKSPACE_ROOT_DIR}"

# download and install AWS SAM CLI
RUN uri=$(echo "https://github.com/aws/aws-sam-cli/releases/download/${AWS_SAM_CLI_VERSION}/aws-sam-cli-${TARGETOS}-${TARGETARCH}.zip" | sed 's/amd64/x86_64/g') && curl -sSL "${uri}" -o "aws-sam-cli.zip" && \
    mkdir -v "${WORKSPACE_ROOT_DIR}/aws-sam-cli" && unzip "aws-sam-cli.zip" -d "${WORKSPACE_ROOT_DIR}/aws-sam-cli" && \
    "${WORKSPACE_ROOT_DIR}/aws-sam-cli/install" --install-dir "/usr/local/aws-sam-cli" --bin-dir "/usr/local/bin"


# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-helm-builder

LABEL stage="aws-cloud-tools-helm-builder" \
      description="Debian-based container builder for preparing AWS cloud tool HELM CLI"

ARG TARGETOS
ARG TARGETARCH
ARG HELM_CLI_VERSION

ARG WORKSPACE_ROOT_DIR

WORKDIR "${WORKSPACE_ROOT_DIR}"

# download HELM archive file
ADD "https://get.helm.sh/helm-${HELM_CLI_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz" "${WORKSPACE_ROOT_DIR}/"

# install HELM
RUN mkdir -v "${WORKSPACE_ROOT_DIR}/helm" && tar -zxf "helm-${HELM_CLI_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz" -C "/usr/local/bin" --strip-components 1 --no-anchored "helm"


# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-kops-builder

LABEL stage="aws-cloud-tools-kubectl-builder" \
      description="Debian-based container builder for preparing AWS cloud tool kops CLI"

ARG TARGETOS
ARG TARGETARCH
ARG KOPS_CLI_VERSION

ARG WORKSPACE_ROOT_DIR

WORKDIR "${WORKSPACE_ROOT_DIR}"

# download kubectl CLI binary file
ADD "https://github.com/kubernetes/kops/releases/download/${KOPS_CLI_VERSION}/kops-${TARGETOS}-${TARGETARCH}" "${WORKSPACE_ROOT_DIR}/"

# install kubectl
RUN install -v -o root -g root -m 0755 "${WORKSPACE_ROOT_DIR}/kops-${TARGETOS}-${TARGETARCH}" "/usr/local/bin/kops"


# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-kubectl-builder

LABEL stage="aws-cloud-tools-kubectl-builder" \
      description="Debian-based container builder for preparing AWS cloud tool kubectl CLI"

ARG TARGETOS
ARG TARGETARCH
ARG KUBECTL_CLI_VERSION

ARG WORKSPACE_ROOT_DIR

WORKDIR "${WORKSPACE_ROOT_DIR}"

# download kubectl CLI binary file
ADD "https://dl.k8s.io/release/${KUBECTL_CLI_VERSION}/bin/linux/${TARGETARCH}/kubectl" "${WORKSPACE_ROOT_DIR}/"

# install kubectl
RUN install -v -o root -g root -m 0755 "${WORKSPACE_ROOT_DIR}/kubectl" "/usr/local/bin/"


# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-terraform-builder

LABEL stage="aws-cloud-tools-terraform-builder" \
      description="Debian-based container builder for preparing AWS cloud tool terraform"

ARG TARGETOS
ARG TARGETARCH
ARG TERRAFORM_CLI_VERSION

ARG WORKSPACE_ROOT_DIR

WORKDIR "${WORKSPACE_ROOT_DIR}"

# download TF CLI archive file
ADD "https://releases.hashicorp.com/terraform/${TERRAFORM_CLI_VERSION}/terraform_${TERRAFORM_CLI_VERSION}_${TARGETOS}_${TARGETARCH}.zip" "${WORKSPACE_ROOT_DIR}/"

# install TF CLI binary
RUN unzip "terraform_${TERRAFORM_CLI_VERSION}_${TARGETOS}_${TARGETARCH}.zip" -d "/usr/local/bin/"


# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-terragrunt-builder

LABEL stage="aws-cloud-tools-kubectl-builder" \
      description="Debian-based container builder for preparing AWS cloud tool terragrunt CLI"

ARG TARGETOS
ARG TARGETARCH
ARG TERRAGRUNT_CLI_VERSION

ARG WORKSPACE_ROOT_DIR

WORKDIR "${WORKSPACE_ROOT_DIR}"

# download kubectl CLI binary file
ADD "https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_CLI_VERSION}/terragrunt_${TARGETOS}_${TARGETARCH}" "${WORKSPACE_ROOT_DIR}/"

# install terragrunt CLI
RUN install -v -o root -g root -m 0755 "${WORKSPACE_ROOT_DIR}/terragrunt_${TARGETOS}_${TARGETARCH}" "/usr/local/bin/terragrunt"


# container as final image for providing AWS cloud tools
FROM debian:${DEBIAN_RELEASE} as aws-cloud-tools-image

LABEL stage="aws-cloud-tools-image" \
      description="Debian-based container with AWS cloud tools"

ARG CONTAINER_USER
ARG CONTAINER_GROUP

ARG DEBIAN_FRONTEND

# enable AWS SAM CLI completion
ADD --chown=${CONTAINER_USER}:${CONTAINER_GROUP} --chmod=0644 "https://raw.githubusercontent.com/daisuke-awaji/sam_completion/master/sam_completion" "/usr/share/bash-completion/completions/sam"

# transfer applications from builders
COPY --from=aws-cloud-tools-aws-cli-builder "/usr/local/aws-cli" "/usr/local/aws-cli"
COPY --from=aws-cloud-tools-aws-cli-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-aws-sam-cli-builder "/usr/local/aws-sam-cli" "/usr/local/aws-sam-cli"
COPY --from=aws-cloud-tools-aws-sam-cli-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-helm-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-kops-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-kubectl-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-terraform-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-terragrunt-builder "/usr/local/bin/" "/usr/local/bin/"

# setup user profile
RUN groupadd --gid 1000 ${CONTAINER_USER} && \
    useradd --gid ${CONTAINER_GROUP} --create-home --uid 1000 ${CONTAINER_USER} && \
# SSH client configuration
    mkdir -v "/home/${CONTAINER_USER}/.ssh" && \
    echo "Host *\n" \
         "IdentitiesOnly yes\n" \
         "ControlPath ~/.ssh/_controlmasters-%r@%h:%p\n" \
         "ControlMaster auto\n" \
         "ControlPersist yes\n" \
         "AddressFamily inet\n" \
         "TCPKeepAlive yes\n" \
         "ConnectionAttempts 1\n" \
         "ConnectTimeout 5\n" \
         "ServerAliveCountMax 2\n" \
         "ServerAliveInterval 15\n" > "/home/${CONTAINER_USER}/.ssh/config" && \
# enable HELM, AWS CLI, TF completion
    helm completion bash > "/usr/share/bash-completion/completions/helm" && \
    kops completion bash > "/usr/share/bash-completion/completions/kops" && \
    kubectl completion bash > "/usr/share/bash-completion/completions/kubectl" && \
    echo "complete -C /usr/local/bin/aws_completer aws" > "/usr/share/bash-completion/completions/aws" && \
    echo "complete -C /usr/local/bin/terraform terraform" > "/usr/share/bash-completion/completions/terraform" && \
    echo "complete -C /usr/local/bin/terragrunt terragrunt" > "/usr/share/bash-completion/completions/terragrunt" && \
# make sure about owner consistency of user profile directory content
    chown -vR ${CONTAINER_USER}:${CONTAINER_GROUP} "/home/${CONTAINER_USER}" && \
# install required packages
    apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y --no-install-recommends install ca-certificates curl wget openssl \
                                               openssh-client autossh \
                                               iputils-ping iproute2 mtr nmap \
                                               mariadb-client postgresql-client sqlite3 \
                                               dnsutils whois dialog \
                                               bc inotify-tools git jq less locales \
                                               bash-completion nano screen tmux && \
    apt-get clean && rm -rf "/var/lib/apt/lists/*" && \
# set locale to UTF-8
    sed --in-place '/en_US.UTF-8/s/^# //' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=C.UTF-8 && \
# disable bell and startup message for screen
    sed --in-place 's/vbell on/vbell off/;/startup_message off/s/^#//' /etc/screenrc

# set locales
ENV LANG C.UTF-8
ENV TZ=UTC

# user home directory as workdir
WORKDIR "/home/${CONTAINER_USER}"

# container user and group
USER "${CONTAINER_USER}:${CONTAINER_GROUP}"

# open shell
CMD ["bash"]
