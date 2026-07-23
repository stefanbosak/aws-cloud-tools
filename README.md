<div align="center">

# ☁️ AWS Cloud Tools

**AWS ecosystem CLI tools (Hardened)**

[![build_status_badge](../../actions/workflows/docker-image-native-multiplatform-pipeline.yaml/badge.svg?branch=main)](.github/workflows/docker-image-native-multiplatform-pipeline.yaml)
[![AWS](https://img.shields.io/badge/Amazon_Web_Services-FF9900?style=for-the-badge&logo=amazonwebservices&logoColor=white)](https://aws.amazon.com/)

</div>

---

## 📦 Latest Build

<!-- VERSION_INFO_START -->
| Component | Version |
|-----------|---------|
| **Ansible** | [`v2.21.2`](https://github.com/ansible/ansible/releases/tag/v2.21.2) |
| **AWS CLI** | [`2.36.7`](https://github.com/aws/aws-cli/releases/tag/2.36.7) |
| **AWS SAM CLI** | [`sam-cli-nightly`](https://github.com/aws/aws-sam-cli/releases/tag/sam-cli-nightly) |
| **AWS session manager** | [`1.2.835.0`](https://github.com/aws/session-manager-plugin/releases/tag/1.2.835.0) |
| **AWS ECR Credential Helper** | [`0.12.0`](https://github.com/awslabs/amazon-ecr-credential-helper/releases/tag/v0.12.0) |
| **cert-manager CLI** | [`v2.5.0`](https://github.com/cert-manager/cmctl/releases/tag/v2.5.0) |
| **Helm** | [`v4.2.3`](https://github.com/helm/helm/releases/tag/v4.2.3) |
| **K9s** | [`v0.51.0`](https://github.com/derailed/k9s/releases/tag/v0.51.0) |
| **Kops** | [`v1.36.0`](https://github.com/kubernetes/kops/releases/tag/v1.36.0) |
| **Kubectl** | [`v1.36.3`](https://github.com/kubernetes/kubernetes/releases/tag/v1.36.3) |
| **Kustomize** | [`5.8.1`](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize/v5.8.1) |
| **SwarmCLI** | [`v1.13.0-rc4`](https://github.com/Eldara-Tech/swarmcli/releases/tag/v1.13.0-rc4) |
| **Terraform** | [`1.16.0-beta1`](https://github.com/hashicorp/terraform/releases/tag/v1.16.0-beta1) |
| **Terragrunt** | [`v1.1.1`](https://github.com/gruntwork-io/terragrunt/releases/tag/v1.1.1) |

> 🔄 Last updated: 2026-07-23T20:37:50Z · [Build #172](https://github.com/stefanbosak/aws-cloud-tools/actions/runs/30042603012)
<!-- VERSION_INFO_END -->

---

## 📋 Overview

This repository provides a fully automated preparation of <span style="color: #0969da;">**containerized**</span>[AWS](https://aws.amazon.com/) environment using <span style="color: #1a7f37;">**Docker-in-Docker**</span> architecture.

### Covered CLI tools

| Tool | Description |
|------|-------------|
| [Ansible](https://docs.ansible.com/ansible/latest/command_guide/command_line_tools.html) | <span style="color: #8250df;">Configuration management and automation</span> |
| [AWS CLI](https://aws.amazon.com/cli/) | <span style="color: #8250df;">Official AWS command-line interface</span> |
| [AWS SAM](https://aws.amazon.com/serverless/sam/) | <span style="color: #8250df;">AWS Serverless Application Model toolkit</span> |
| [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) | <span style="color: #8250df;">AWS Systems Manager Session Manager</span> |
| [AWS Credential Helper](https://github.com/awslabs/amazon-ecr-credential-helper) | <span style="color: #8250df;">Amazon ECR Docker Credential Helper</span> |
| [cert-manager CLI](https://github.com/cert-manager/cmctl/) | <span style="color: #d73a49;">cert-manager CLI</span> |
| [CNPG CLI](https://github.com/cloudnative-pg/cloudnative-pg/) | <span style="color: #d73a49;">CloudNativePG CLI</span> |
| [Docker CLI](https://docker.com) | <span style="color: #d73a49;">Container management CLI</span> |
| [Helm](https://helm.sh/docs/helm/) | <span style="color: #0969da;">Kubernetes package manager</span> |
| [Kubernetes Operations (kOps)](https://kops.sigs.k8s.io/) | <span style="color: #0969da;">Kubernetes cluster management</span> |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) | <span style="color: #0969da;">Kubernetes command-line tool</span> |
| [k9s](https://k9scli.io/) | <span style="color: #0969da;">Terminal UI for Kubernetes</span> |
| [kustomize](https://kustomize.io/) | <span style="color: #0969da;">Kubernetes native configuration management</span> |
| [SwarmCLI](https://github.com/Eldara-Tech/swarmcli) | <span style="color: #0969da;">Terminal UI for Docker Swarm</span> |
| [Terraform](https://developer.hashicorp.com/terraform/cli) | <span style="color: #1a7f37;">Infrastructure as Code tool</span> |
| [Terragrunt](https://terragrunt.gruntwork.io/) | <span style="color: #1a7f37;">Terraform wrapper for DRY configurations</span> |

> [!NOTE]
> Every script and file is reasonably well commented and relevant details can be found there.

> [!IMPORTANT]
> Check details before taking any action.

> [!CAUTION]
> User is responsible for any modification and execution of any parts from this repository.

---

## ⚡ Zero Effort Approach

GitHub Actions workflow file covers all necessary activities which are fully automated in GitHub (re-using Docker container approach as base for automation):

- <span style="color: #1a7f37;">Gathering and propagating latest available tools versions to Docker preparation process</span>
- <span style="color: #0969da;">Building Docker hardened image</span>

---

## 🐳 Docker Container Approach

Docker build wrapper script covers creation of a container built from a multistage Dockerfile using parallel execution of several builders to speed up preparation. Generated image contains all mentioned tools with pre-enabled Bash completions. Docker run wrapper simplifies application execution.

| File | Description |
|------|-------------|
| [`Dockerfile`](Dockerfile) | <span style="color: #0969da;">Recipe for preparation of Docker container</span> |
| [`.docker`](.docker) | <span style="color: #8250df;">Directory for configuration data persistency (can be mapped into container)</span> |
| [`run.sh`](run.sh) | <span style="color: #8250df;">Container run wrapper/helper script</span> |

### 🏗️ Container Images

| Registry | Network Support | Pull Command |
|----------|----------------|--------------|
| [**DockerHub CR**](https://hub.docker.com/r/developmententity/aws-cloud-tools) | <span style="color: #1a7f37;">IPv4 & IPv6</span> | `docker pull developmententity/aws-cloud-tools:initial` |
| [**GitHub CR**](https://github.com/users/stefanbosak/packages/container/package/aws-cloud-tools) | <span style="color: #8250df;">IPv4 only</span> | `docker pull ghcr.io/stefanbosak/aws-cloud-tools:initial` |

---

## 🌍 AWS Environment

AWS environment can be used via aws-cloud-tools container which is automatically generated and available within ghcr.io. The dedicated `run.sh` script pulls and runs the up-to-date container.

---

<div align="center">

<span style="color: #8250df;">**Made with ❤️ for ☁️ AWS ecosystem and 🔒 security**</span>

</div>
