# set location of workspace directory
# (temporary space within container image)
ARG WORKSPACE_ROOT_DIR=/tmp/workspace

# user in container
ARG CONTAINER_USER=user
ARG CONTAINER_GROUP=user

# Debian release and options
ARG DEBIAN_RELEASE=stable-slim
ARG DEBIAN_FRONTEND=noninteractive

# ansible CLI tools versions
ARG ANSIBLE_CLI_VERSION=2.19.0b4

# AWS CLI tools versions
ARG AWS_CLI_VERSION=2.27.12
ARG AWS_SAM_CLI_VERSION=v1.139.0

# Helm version
ARG HELM_CLI_VERSION=v3.18.0

# kubectl version
ARG K9S_CLI_VERSION=v0.50.6

# kops version
ARG KOPS_CLI_VERSION=v1.32.0

# kubectl version
ARG KUBECTL_CLI_VERSION=v1.33.1

# Terraform version
ARG TERRAFORM_CLI_VERSION=1.12.1

# Terragrunt version
ARG TERRAGRUNT_CLI_VERSION=v0.80.2


# container as builder for preparing AWS cloud tools
FROM debian:${DEBIAN_RELEASE} AS aws-cloud-tools-builder

LABEL stage="aws-cloud-tools-builder" \
      description="Debian-based container builder for preparing AWS cloud tools" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tools" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

ARG DEBIAN_FRONTEND

ARG WORKSPACE_ROOT_DIR
WORKDIR "${WORKSPACE_ROOT_DIR}"

# install required packages and additional applications
RUN apt-get update && \
    apt-get -y --no-install-recommends install ca-certificates binutils curl unzip && \
    apt-get clean && rm -rf "/var/lib/apt/lists/*"

# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-ansible-cli-builder

LABEL stage="aws-cloud-tools-ansible-cli-builder" \
      description="Debian-based container builder for preparing AWS cloud tool ansible" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tool ansible" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

ARG TARGETOS
ARG TARGETARCH
ARG ANSIBLE_CLI_VERSION

ARG WORKSPACE_ROOT_DIR
WORKDIR "${WORKSPACE_ROOT_DIR}"

# download and install ansible tool
RUN apt-get -y --no-install-recommends install python3-pip && \
    apt-get clean && rm -rf "/var/lib/apt/lists/*"
RUN python3 -m pip install --break-system-packages  "https://github.com/ansible/ansible/archive/refs/tags/${ANSIBLE_CLI_VERSION}.tar.gz"


# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-aws-cli-builder

LABEL stage="aws-cloud-tools-aws-cli-builder" \
      description="Debian-based container builder for preparing AWS cloud tool AWS CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tool AWS CLI" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

ARG TARGETOS
ARG TARGETARCH
ARG AWS_CLI_VERSION

ARG WORKSPACE_ROOT_DIR
WORKDIR "${WORKSPACE_ROOT_DIR}"

# download AWS CLI, AWS session-manager-plugin
RUN uri=$(echo "https://awscli.amazonaws.com/awscli-exe-${TARGETOS}-${TARGETARCH}-${AWS_CLI_VERSION}.zip" | sed -e 's/amd64/x86_64/g' -e 's/arm64/aarch64/g') && curl -sSL "${uri}" -o "awscli.zip" && \
    uri=$(echo "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_${TARGETARCH}/session-manager-plugin.deb" | sed -e 's/amd64/64bit/g') && curl -sSLO "${uri}"

# install AWS CLI, AWS session-manager-plugin
RUN mkdir -v "${WORKSPACE_ROOT_DIR}/awscli" && unzip "awscli.zip" -d "${WORKSPACE_ROOT_DIR}/awscli" && \
    "${WORKSPACE_ROOT_DIR}/awscli/aws/install" --install-dir "/usr/local/aws-cli" --bin-dir "/usr/local/bin" && \
    ar x "${WORKSPACE_ROOT_DIR}/session-manager-plugin.deb" && \
    tar -xvf data.tar.gz -C "${WORKSPACE_ROOT_DIR}" && \
    mv "${WORKSPACE_ROOT_DIR}/usr/local/sessionmanagerplugin/bin/session-manager-plugin" "/usr/local/bin"

# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-aws-sam-cli-builder

LABEL stage="aws-cloud-tools-aws-sam-cli-builder" \
      description="Debian-based container builder for preparing AWS cloud tool AWS SAM CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tool AWS SAM CLI" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

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
      description="Debian-based container builder for preparing AWS cloud tool HELM CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tool HELM CLI" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

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
      description="Debian-based container builder for preparing AWS cloud tool kops CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tool kops CLI" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

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
      description="Debian-based container builder for preparing AWS cloud tool kubectl CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tool kubectl CLI" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

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
FROM aws-cloud-tools-builder AS aws-cloud-tools-k9s-builder

LABEL stage="aws-cloud-tools-k9s-builder" \
      description="Debian-based container builder for preparing AWS cloud tool k9s CLI"

ARG TARGETOS
ARG TARGETARCH
ARG K9S_CLI_VERSION

ARG WORKSPACE_ROOT_DIR
WORKDIR "${WORKSPACE_ROOT_DIR}"

# download k9s CLI binary file
ADD "https://github.com/derailed/k9s/releases/download/${K9S_CLI_VERSION}/k9s_Linux_${TARGETARCH}.tar.gz" "${WORKSPACE_ROOT_DIR}/"

# install k9s
RUN tar -zxf "k9s_Linux_${TARGETARCH}.tar.gz" -C "/usr/local/bin" --no-anchored "k9s"

# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-terraform-builder

LABEL stage="aws-cloud-tools-terraform-builder" \
      description="Debian-based container builder for preparing AWS cloud tool terraform" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tool terraform" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

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
      description="Debian-based container builder for preparing AWS cloud tool terragrunt CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tool terragrunt CLI" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

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
FROM debian:${DEBIAN_RELEASE} AS aws-cloud-tools-image

LABEL stage="aws-cloud-tools-image" \
      description="Debian-based container with AWS cloud tools" \
      org.opencontainers.image.description="Debian-based container with AWS cloud tools" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools


ARG CONTAINER_USER
ARG CONTAINER_GROUP

ARG DEBIAN_FRONTEND

# set locales
ENV LANG=C.UTF-8
ENV TZ=UTC

# setup user profile
RUN groupadd --gid 1000 ${CONTAINER_USER} && \
    useradd --gid ${CONTAINER_GROUP} --groups sudo,${CONTAINER_USER} --create-home --uid 1000 ${CONTAINER_USER} && \
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
# make sure about owner consistency of user profile directory content
    chown -vR ${CONTAINER_USER}:${CONTAINER_GROUP} "/home/${CONTAINER_USER}" && \
# install required packages
    apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get -y --no-install-recommends install ca-certificates curl wget openssl \
                                               openssh-client autossh plocate sudo \
                                               iputils-ping iproute2 mtr nmap lsof \
                                               mariadb-client postgresql-client sqlite3 \
                                               dnsutils whois dialog python3-argcomplete \
                                               bc inotify-tools git jq less locales \
                                               bash-completion nano screen tmux vim && \
    apt-get clean && rm -rf "/var/lib/apt/lists/*" && \
# set locale to UTF-8
    sed --in-place '/en_US.UTF-8/s/^# //' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=C.UTF-8 && \
# disable bell and startup message for screen
    sed --in-place 's/vbell on/vbell off/;/startup_message off/s/^#//' /etc/screenrc && \
# allow sudo without password for CONTAINER_USER
    echo "${CONTAINER_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${CONTAINER_USER}" && \
# update plocate database
    updatedb && \
# enable tools completions (not required to run any tool)
    echo "complete -C aws_completer aws" > "/usr/share/bash-completion/completions/aws" && \
    echo "complete -C terraform terraform" > "/usr/share/bash-completion/completions/terraform" && \
    echo "complete -C terragrunt terragrunt" > "/usr/share/bash-completion/completions/terragrunt"

# enable AWS SAM CLI (v1.58) completion
ADD --chown=${CONTAINER_USER}:${CONTAINER_GROUP} --chmod=0644 "https://raw.githubusercontent.com/demotodo/sam_completion/master/sam_completion" "/usr/share/bash-completion/completions/sam"

# transfer tools from builders
COPY --from=aws-cloud-tools-ansible-cli-builder "/usr/local/bin" "/usr/local/bin"
COPY --from=aws-cloud-tools-ansible-cli-builder "/usr/local/lib/" "/usr/local/lib"
COPY --from=aws-cloud-tools-aws-cli-builder "/usr/local/aws-cli" "/usr/local/aws-cli"
COPY --from=aws-cloud-tools-aws-cli-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-aws-sam-cli-builder "/usr/local/aws-sam-cli" "/usr/local/aws-sam-cli"
COPY --from=aws-cloud-tools-aws-sam-cli-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-helm-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-kops-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-kubectl-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-k9s-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-terraform-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-terragrunt-builder "/usr/local/bin/" "/usr/local/bin/"

# enable tools completions (required to run given tool to generate completion file content)
RUN helm completion bash > "/usr/share/bash-completion/completions/helm" && \
    kops completion bash > "/usr/share/bash-completion/completions/kops" && \
    kubectl completion bash > "/usr/share/bash-completion/completions/kubectl" && \
    k9s completion bash > "/usr/share/bash-completion/completions/k9s" && \
    activate-global-python-argcomplete && \
# DiD (Docker in Docker)
# - DinD via QEMU on ARM64 is not supported
#   (ARM64 requires ARM64 kernel from host system which is not present on AMD64 host)
    curl -fsSL https://get.docker.com | sh && \
    if ! getent group docker > /dev/null 2>&1; then \
      groupadd docker; \
    fi && \
    usermod -aG docker "${CONTAINER_USER}"

# user home directory as workdir
WORKDIR "/home/${CONTAINER_USER}"

# container user and group
USER "${CONTAINER_USER}:${CONTAINER_GROUP}"

# open shell
CMD ["bash"]
