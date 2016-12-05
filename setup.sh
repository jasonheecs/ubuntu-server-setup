#!/bin/bash

set -e

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo "${current_dir}"
}

function includeDependencies() {
    # shellcheck source=./setupLibrary.sh
    source "${current_dir}/setupLibrary.sh"
}

current_dir=$(getCurrentDir)
includeDependencies
output_file="output.log"

function setupSwap() {
    createSwap
    mountSwap
    tweakSwapSettings "10" "50"
    saveSwapSettings
}

function hasSwap() {
    [[ "$(sudo swapon -s)" == *"/swapfile"* ]]
}

function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

function logTimestamp() {
    local filename=${1}
    {
        echo "===================" 
        echo "Log generated on $(date)"
        echo "==================="
    } >>"${filename}" 2>&1
}

read -rp "Enter the username of the new user account:" username
read -s -rp "Enter new UNIX password:" password
printf "\n"
read -s -rp "Retype new UNIX password:" password_confirmation
printf "\n"

if [[ "${password}" != "${password_confirmation}" ]]; then
    echo "Passwords do not match!"
    exit 1
fi

trap cleanup EXIT SIGHUP SIGINT SIGTERM

addUserAccount "${username}" "${password}"

read -rp $'Paste in the public SSH key for the new user:\n' sshKey
echo 'Running setup script...'
logTimestamp "${output_file}"

exec 3>&1 >>"${output_file}" 2>&1
disableSudoPassword "${username}"
addSSHKey "${username}" "${sshKey}"
changeSSHConfig
setupUfw

if ! hasSwap; then
    setupSwap
fi

timezone="Asia/Singapore"
setTimezone "${timezone}"
echo "Timezone is set to ${timezone}" >&3

configureNTP

sudo service ssh restart

cleanup

echo "Setup Done! Log file is located at ${output_file}" >&3