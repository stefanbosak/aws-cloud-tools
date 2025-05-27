#!/bin/bash
#
# Wrapper to automatically detect and set latest
# available versions for all of related tools
#
cwd=$(dirname $(realpath "${0}"))

# create temporary workspace
TMP_DIR=$(mktemp -d)
#TMP_ENV_FILE="${TMP_DIR}/environment"
TMP_SCRIPT="${TMP_DIR}/script.sh"

# register cleanup handler for removing temporary workspace
trap 'rm -fr ${TMP_DIR}' EXIT

# when environment file already exits
if [[ ! -f "${GITHUB_ENV_TAIL_FILE}" ]]; then
  # generate environment variables data
  "${cwd}/get_versions_strings.sh" | tr ':' '=' | tr -d '\n' | tr ';' '\n' > "${GITHUB_ENV_TAIL_FILE}"
fi

# generate temporary script
echo "#!/bin/bash" > "${TMP_SCRIPT}"
sed 's/^/export /g' "${GITHUB_ENV_TAIL_FILE}" >> "${TMP_SCRIPT}"

# make script executable
chmod +x "${TMP_SCRIPT}"

# source content of temporary script
# publish exports to who called me
# (this script)
source "${TMP_SCRIPT}"
