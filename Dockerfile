# user in container
ARG CONTAINER_USER=user
ARG CONTAINER_GROUP=user

ARG CONTAINER_USER_ID=1000
ARG CONTAINER_GROUP_ID=1000

# set location of workspace directory
# (temporary space within container image)
ARG WORKSPACE_ROOT_DIR="/home/${CONTAINER_USER}"

# Debian release and options
ARG DEBIAN_RELEASE=trixie-debian13-dev
ARG DEBIAN_FRONTEND=noninteractive

# ansible CLI tools versions
ARG ANSIBLE_CLI_VERSION=v2.20.6rc1

# AWS CLI tools versions
ARG AWS_CLI_VERSION=2.34.46
ARG AWS_SAM_CLI_VERSION=sam-cli-nightly
ARG AWS_SM_CLI_VERSION=1.2.814.0
ARG AWS_CH_CLI_VERSION=0.12.0

# cert-manager CLI version
ARG CM_CTL_CLI_VERSION=v2.5.0

# Helm version
ARG HELM_CLI_VERSION=v4.1.4

# kubectl version
ARG K9S_CLI_VERSION=v0.50.18

# kops version
ARG KOPS_CLI_VERSION=v1.35.0

# kubectl version
ARG KUBECTL_CLI_VERSION=v1.36.1

# Kustomize version
ARG KUSTOMIZE_CLI_VERSION=5.8.1

# Terraform version
ARG TERRAFORM_CLI_VERSION=1.15.2

# Terragrunt version
ARG TERRAGRUNT_CLI_VERSION=v1.0.4

# container as builder for preparing AWS cloud tools
FROM dhi.io/debian-base:${DEBIAN_RELEASE} AS aws-cloud-tools-builder

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
RUN apt-get -y --no-install-recommends install python-is-python3 python3-pip && \
    apt-get clean && rm -rf "/var/lib/apt/lists/*"
RUN python3 -m pip install --break-system-packages "https://github.com/ansible/ansible/archive/refs/tags/${ANSIBLE_CLI_VERSION}.tar.gz"


# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-aws-cli-builder

LABEL stage="aws-cloud-tools-aws-cli-builder" \
      description="Debian-based container builder for preparing AWS cloud tool AWS CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tool AWS CLI" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

ARG TARGETOS
ARG TARGETARCH
ARG AWS_CLI_VERSION
ARG AWS_SM_CLI_VERSION
ARG AWS_CH_CLI_VERSION

ARG WORKSPACE_ROOT_DIR
WORKDIR "${WORKSPACE_ROOT_DIR}"

# download AWS CLI, AWS session-manager-plugin, AWS credential helper plugin
RUN mkdir -p "/usr/local/bin" && \
    uri=$(echo "https://awscli.amazonaws.com/awscli-exe-${TARGETOS}-${TARGETARCH}-${AWS_CLI_VERSION}.zip" | sed -e 's/amd64/x86_64/g' -e 's/arm64/aarch64/g') && curl -sSL "${uri}" -o "awscli.zip" && \
    uri=$(echo "https://s3.amazonaws.com/session-manager-downloads/plugin/${AWS_SM_CLI_VERSION}/ubuntu_${TARGETARCH}/session-manager-plugin.deb" | sed -e 's/amd64/64bit/g') && curl -sSLO "${uri}" && \
    curl -sSL "https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${AWS_CH_CLI_VERSION}/linux-${TARGETARCH}/docker-credential-ecr-login" -o "/usr/local/bin/docker-credential-ecr-login" && \
    chmod a+x "/usr/local/bin/docker-credential-ecr-login"

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
    "${WORKSPACE_ROOT_DIR}/aws-sam-cli/install" --install-dir "/usr/local/aws-sam-cli" --bin-dir "/usr/local/bin" && \
    [ -e /usr/local/bin/sam ] || ln -s "/usr/local/bin/sam-nightly" "/usr/local/bin/sam"


# container as builder for preparing aws cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-cm-builder

LABEL stage="aws-cloud-tools-cm-builder" \
      description="Debian-based container builder for preparing aws cloud tool cert-manager CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing aws cloud tool cert-manager CLI" \
      org.opencontainers.image.url=https://github.com/stefanbosak/aws-cloud-tools \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

ARG TARGETOS
ARG TARGETARCH
ARG CM_CTL_CLI_VERSION

ARG WORKSPACE_ROOT_DIR
WORKDIR "${WORKSPACE_ROOT_DIR}"

# download cert-manager
ADD "https://github.com/cert-manager/cmctl/releases/download/${CM_CTL_CLI_VERSION}/cmctl_linux_${TARGETARCH}" "${WORKSPACE_ROOT_DIR}/cmctl_linux_${TARGETARCH}"

# install cert-manager
RUN mkdir -p "/usr/local/bin/" && install -v -o root -g root -m 0755 "${WORKSPACE_ROOT_DIR}/cmctl_linux_${TARGETARCH}" "/usr/local/bin/kubectl-cert_manager"


# container as builder for preparing aws cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-cnpg-builder

LABEL stage="aws-cloud-tools-cnpg-builder" \
      description="Debian-based container builder for preparing aws cloud tool CNPG CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing aws cloud tool CNPG CLI" \
      org.opencontainers.image.url=https://github.com/stefanbosak/aws-cloud-tools \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

ARG TARGETOS
ARG TARGETARCH

ARG WORKSPACE_ROOT_DIR
WORKDIR "${WORKSPACE_ROOT_DIR}"

# install kubectl CNPG plugin
RUN mkdir -p "/usr/local/bin/" && \
    curl -sSfL https://github.com/cloudnative-pg/cloudnative-pg/raw/main/hack/install-cnpg-plugin.sh | \
    sh -s -- -b /usr/local/bin

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
RUN mkdir -p "/usr/local/bin/" && tar -xvf "${WORKSPACE_ROOT_DIR}/helm-${HELM_CLI_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz" -C "/usr/local/bin" --strip-components 1 --no-anchored "helm"


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
RUN mkdir -p "/usr/local/bin/" && tar -xvf "${WORKSPACE_ROOT_DIR}/k9s_Linux_${TARGETARCH}.tar.gz" -C "/usr/local/bin" --no-anchored "k9s"


# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-kops-builder

LABEL stage="aws-cloud-tools-kops-builder" \
      description="Debian-based container builder for preparing AWS cloud tool kops CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing AWS cloud tool kops CLI" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

ARG TARGETOS
ARG TARGETARCH
ARG KOPS_CLI_VERSION

ARG WORKSPACE_ROOT_DIR
WORKDIR "${WORKSPACE_ROOT_DIR}"

# download kops CLI binary file
ADD "https://github.com/kubernetes/kops/releases/download/${KOPS_CLI_VERSION}/kops-${TARGETOS}-${TARGETARCH}" "${WORKSPACE_ROOT_DIR}/"

# install kubectl
RUN mkdir -p "/usr/local/bin/" && install -v -o root -g root -m 0755 "${WORKSPACE_ROOT_DIR}/kops-${TARGETOS}-${TARGETARCH}" "/usr/local/bin/kops"


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
RUN mkdir -p "/usr/local/bin/" && install -v -o root -g root -m 0755 "${WORKSPACE_ROOT_DIR}/kubectl" "/usr/local/bin/kubectl"


# container as builder for preparing aws cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-kustomize-builder

LABEL stage="aws-cloud-tools-kustomize-builder" \
      description="Debian-based container builder for preparing aws cloud tool kustomize CLI" \
      org.opencontainers.image.description="Debian-based container builder for preparing aws cloud tool kustomize CLI" \
      org.opencontainers.image.url=https://github.com/stefanbosak/aws-cloud-tools \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

ARG TARGETOS
ARG TARGETARCH
ARG KUSTOMIZE_CLI_VERSION

ARG WORKSPACE_ROOT_DIR
WORKDIR "${WORKSPACE_ROOT_DIR}"

# download kustomize archive
ADD "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v${KUSTOMIZE_CLI_VERSION}/kustomize_v${KUSTOMIZE_CLI_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz" "${WORKSPACE_ROOT_DIR}/"

# install kustomize
RUN mkdir -p "/usr/local/bin/" && tar -xvf "${WORKSPACE_ROOT_DIR}/kustomize_v${KUSTOMIZE_CLI_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz" -C "/usr/local/bin" --no-anchored "kustomize"


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
RUN mkdir -p "/usr/local/bin/" && unzip "terraform_${TERRAFORM_CLI_VERSION}_${TARGETOS}_${TARGETARCH}.zip" -d "/usr/local/bin/"


# container as builder for preparing AWS cloud tools
FROM aws-cloud-tools-builder AS aws-cloud-tools-terragrunt-builder

LABEL stage="aws-cloud-tools-terragrunt-builder" \
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
RUN mkdir -p "/usr/local/bin/" && install -v -o root -g root -m 0755 "${WORKSPACE_ROOT_DIR}/terragrunt_${TARGETOS}_${TARGETARCH}" "/usr/local/bin/terragrunt"


# container as final image for providing AWS cloud tools
FROM dhi.io/debian-base:${DEBIAN_RELEASE} AS aws-cloud-tools-image

LABEL stage="aws-cloud-tools-image" \
      description="Debian-based container with AWS cloud tools" \
      org.opencontainers.image.description="Debian-based container with AWS cloud tools" \
      org.opencontainers.image.source=https://github.com/stefanbosak/aws-cloud-tools

ARG TARGETARCH

ARG CONTAINER_USER
ARG CONTAINER_GROUP

ARG CONTAINER_USER_ID
ARG CONTAINER_GROUP_ID

ARG DEBIAN_FRONTEND

ARG HOME_ROOT_DIR="/home/${CONTAINER_USER}"
WORKDIR "${HOME_ROOT_DIR}"

# setup user profile
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      bash-completion \
      bc \
      ca-certificates \
      curl \
      dnsutils \
      git \
      gzip \
      iproute2 \
      iputils-ping \
      jq \
      kmod \
      lsof \
      openssh-client \
      pigz \
      procps \
      psmisc \
      python-is-python3 \
      python3-venv \
      python3-argcomplete \
      ripgrep \
      rsync \
      socat \
      unzip \
      wget \
      whois \
    && apt-get clean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# enable AWS SAM CLI (v1.58) completion
ADD --chown=${CONTAINER_USER}:${CONTAINER_GROUP} --chmod=0644 "https://raw.githubusercontent.com/demotodo/sam_completion/master/sam_completion" "/usr/share/bash-completion/completions/sam"

# transfer tools from builders
COPY --from=aws-cloud-tools-ansible-cli-builder "/usr/local/bin" "/usr/local/bin"
COPY --from=aws-cloud-tools-ansible-cli-builder "/usr/local/lib/" "/usr/local/lib"
COPY --from=aws-cloud-tools-aws-cli-builder "/usr/local/aws-cli" "/usr/local/aws-cli"
COPY --from=aws-cloud-tools-aws-cli-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-aws-sam-cli-builder "/usr/local/aws-sam-cli" "/usr/local/aws-sam-cli"
COPY --from=aws-cloud-tools-aws-sam-cli-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-cm-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-cnpg-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-helm-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-k9s-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-kops-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-kubectl-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-kustomize-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-terraform-builder "/usr/local/bin/" "/usr/local/bin/"
COPY --from=aws-cloud-tools-terragrunt-builder "/usr/local/bin/" "/usr/local/bin/"

# install DiD (Docker in Docker)
# - DinD via QEMU on ARM64 is not supported
#   (ARM64 requires ARM64 kernel from host system which is not present on AMD64 host)
RUN curl -fsSL https://test.docker.com | sh && \
    if ! getent group docker > /dev/null 2>&1; then \
      groupadd docker; \
    fi

# setup user and group
RUN if getent group "${CONTAINER_GROUP_ID}" > /dev/null; then \
      _existing_group="$(getent group "${CONTAINER_GROUP_ID}" | cut -d: -f1)"; \
      if [ "${_existing_group}" != "${CONTAINER_GROUP}" ]; then \
        groupmod -n "${CONTAINER_GROUP}" "${_existing_group}"; \
      fi; \
    else \
      groupadd --gid "${CONTAINER_GROUP_ID}" "${CONTAINER_GROUP}"; \
    fi \
    && if getent passwd "${CONTAINER_USER_ID}" > /dev/null; then \
         _existing_user="$(getent passwd "${CONTAINER_USER_ID}" | cut -d: -f1)"; \
         if [ "${_existing_user}" != "${CONTAINER_USER}" ]; then \
           if [ -d "/home/${_existing_user}" ]; then \
             mv "/home/${_existing_user}" "/home/${CONTAINER_USER}"; \
           fi; \
           usermod -d "${HOME_ROOT_DIR}" -l "${CONTAINER_USER}" "${_existing_user}"; \
         fi; \
       else \
         useradd \
           --uid "${CONTAINER_USER_ID}" \
           --gid "${CONTAINER_GROUP_ID}" \
           --groups "${CONTAINER_GROUP}" \
           -M -d "${HOME_ROOT_DIR}" \
           -s /bin/bash \
           "${CONTAINER_USER}"; \
       fi \
    && chown -R "${CONTAINER_USER}:${CONTAINER_GROUP}" "${HOME_ROOT_DIR}" \
    && usermod -aG docker "${CONTAINER_USER}"


# enable tools completions (required to run given tool to generate completion file content)
RUN echo "complete -C aws_completer aws" > "/usr/share/bash-completion/completions/aws" && \
    ln -s /usr/local/bin/kubectl-cert_manager /usr/local/bin/cmctl && \
    cmctl completion bash > /usr/share/bash-completion/completions/cmctl && \
    ln -s /usr/local/bin/kubectl-cnpg /usr/local/bin/cnpgctl && \
    cnpgctl completion bash > /usr/share/bash-completion/completions/cnpgctl && \
    sed -i 's/kubectl-cnpg/cnpgctl/g' /usr/share/bash-completion/completions/cnpgctl && \
    helm completion bash > "/usr/share/bash-completion/completions/helm" && \
    k9s completion bash > "/usr/share/bash-completion/completions/k9s" && \
    kops completion bash > "/usr/share/bash-completion/completions/kops" && \
    kubectl completion bash > "/usr/share/bash-completion/completions/kubectl" && \
    cp "/usr/share/bash-completion/completions/kubectl" "/usr/share/bash-completion/completions/k" && \
    sed -i 's/kubectl/k/g' "/usr/share/bash-completion/completions/k" && \
    ln -s /usr/local/bin/kubectl /usr/local/bin/k && \
    kustomize completion bash > "/usr/share/bash-completion/completions/kustomize" && \
    echo "complete -C terraform terraform" > "/usr/share/bash-completion/completions/terraform" && \
    echo "complete -C terragrunt terragrunt" > "/usr/share/bash-completion/completions/terragrunt" && \
    activate-global-python-argcomplete


# container user and group
USER "${CONTAINER_USER}:${CONTAINER_GROUP}"

WORKDIR "${HOME_ROOT_DIR}"

RUN cp /etc/skel/.bashrc /etc/skel/.profile "${HOME_ROOT_DIR}"

# open shell
CMD ["bash"]
