# aws-cloud-tools

Aim of this repository is to provide flexible helpers/wrappers for preparing
common tools (pre-defined versions) frequently required when working
with [AWS](https://aws.amazon.com/) ecosystem/environment. 

covered common CLI tools to interact with AWS ecosystem:
- [Ansible CLI](https://docs.ansible.com/ansible/latest/command_guide/command_line_tools.html)
- [AWS CLI](https://aws.amazon.com/cli/)
- [AWS SAM CLI](https://github.com/aws/aws-sam-cli)
- [HELM CLI](https://helm.sh/docs/helm/)
- [kops CLI](https://kops.sigs.k8s.io/)
- [kubectl CLI](https://kubernetes.io/docs/reference/kubectl/)
- [k9s CLI](https://k9scli.io/)
- [Terraform CLI](https://developer.hashicorp.com/terraform/cli)
- [Terragrunt CLI](https://terragrunt.gruntwork.io/)
- [Docker CLI](https://docker.com)

> [!NOTE]
> Every script and file would be reasonable well commented and relevant details can be found there.

> [!IMPORTANT]
> Check details before taking any action.

> [!CAUTION]
> User is responsible for any modification and execution of any parts from this repository.

__shared scripts:__
- [setvariables.sh](setvariables.sh): set required versions for above mentioned tools
- [get_versions_string.sh](get_versions_strings.sh): get versions strings for above mentioned tools
- [set_latest_versions_strings.sh](set_latest_versions_strings.sh): set latest versions strings for above mentioned tools as environment variables

### Zero effort approach
GitHub Actions workflow file is covering all necessary activities which are fully automated in GitHub (re-using Docker container approach as base for automation):
- gathering and propagating latest available tools versions to Docker preparation process
- setting up of QEMU emulator (support for multi platform images)
- setting up of Docker builder
- building Docker image
- testing of created Docker image
- tagging of tested Docker image
- pushing of tagged Docker image into GitHub container registry
- capturing pushed versions details within [PUSHED_CLI_VERSIONS.txt](PUSHED_CLI_VERSIONS.txt) which is generated, commited and pushed into repository automatically within related workflow steps
- DinD (Docker in Docker) has been included (required to start Docker service when needed and apply custom Docker configuration if needed)

__GitHub Actions workflow run triggering options:__
- automatically by scheduler at the specified time (latest versions will be included)
- manually by user:
  - without providing any parameter(s) (latest versions will be included)
  - any version parameter(s) can be specified as input (filled versions will be included)

__Hint for local execution of GitHub Actions workflow file__
- [act tool](https://github.com/nektos/act/blob/master/README.md) can be used (read documentation first)
  - [act tool install script](https://raw.githubusercontent.com/nektos/act/master/install.sh)

__scripts and files:__
- [![build_status_badge](../..//actions/workflows/docker-image-prepare-amd64-arm64.yml/badge.svg?branch=main)](.github/workflows/docker-image-prepare-amd64-arm64.yml): GitHub Actions workflow file for automation of Docker image preparation (amd64, arm64)
- [![build_status_badge](../../actions/workflows/docker-image-test-amd64-arm64.yml/badge.svg?branch=main)](.github/workflows/docker-image-test-amd64-arm64.yml)
: GitHub Actions workflow file for automation of Docker image testing (amd64, arm64)
- [act.sh](act.sh): act script for local execution of GitHub actions workflows pre-configured to operate in dry-run mode (check script before first run)

__supported platforms (OS/architecture):__
- linux/amd64 (e.g. Intel/AMD)
- linux/arm64 (e.g. Ampere/Cortex/AppleMx/RaspberryPi)

Pull images from following container registries (platform is recognized and selected automatically):
- [DockerHubCR](https://hub.docker.com/r/developmententity/aws-cloud-tools) (IPv4 & IPv6): `docker pull developmententity/aws-cloud-tools:initial`
- [GitHubCR](https://github.com/users/stefanbosak/packages/container/package/aws-cloud-tools) (IPv4 only): `docker pull ghcr.io/stefanbosak/aws-cloud-tools:initial`

### Docker container approach
Docker build wrapper script is covering creation of container
which will be created based on multistage Dockerfile using
parallel execuction of several builders to speed-up preparation.
Generated image will contains all of above mentioned tools
and also pre-enabled corresponding Bash completions.
Docker run wrapper would simplify application execution.

__scripts and files:__
- [Dockerfile](Dockerfile): recipie for preparation of Docker container
- [docker-build.sh](docker-build.sh):  wrapper as Docker builder script
- [docker-run.sh](docker-run.sh): wrapper as Docker runner script
- [docker-push.sh](docker-push.sh): wrapper for uploading image to container repository configured user
- [docker-versions.sh](docker-versions.sh): wrapper for showing tools versions
- [.docker](.docker): .docker directory for covering configuration data persistency (can be mapped into container)

__additional applications included__
Following tools are using latest available version within given Linux distribution release (when Docker image has been built/prepared):
- [MariaDB CLI](https://mariadb.com/kb/en/mysql-command-line-client/)
- [PostgreSQL CLI](https://www.postgresql.org/docs/current/app-psql.html)
- [SQLite3 CLI](https://sqlite.org/cli.html)

### Standalone installer approach
Dedicated installer wrapper script is covering all of above mentioned tools.
Related applications will be intalled directly on system where
standalone-install.sh script will be executed. Bash completion
will be also pre-enabled for all corresponding tools. Uninstallation is supported.
To run this script user has to able to have root priviledges (e.g. run via sudo).

__scripts and files:__
- [![build_status_badge](../../actions/workflows/standalone-test-amd64-arm64.yml/badge.svg?branch=main)](.github/workflows/standalone-test-amd64.yml): standalone installer script
