#!/bin/bash

set -e

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo ${current_dir}
}

function includeDependencies() {
    source "${current_dir}/setupLibrary.sh"
}

current_dir=$(getCurrentDir)
includeDependencies

function setupSwap() {
    createSwap
    mountSwap
    tweakSwapSettings "10" "50"
    saveSwapSettings
}

function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

read -p "Enter the username of the new user account:" username
read -s -p "Enter new UNIX password:" password
printf "\n"
read -s -p "Retype new UNIX password:" password_confirmation
printf "\n"

if [[ "${password}" != "${password_confirmation}" ]]; then
    echo "Passwords do not match!"
    exit 1
fi

trap cleanup EXIT SIGHUP SIGINT SIGTERM

addUserAccount "${username}" "${password}"

read -rp $'Paste in the public SSH key for the new user:\n' sshKey
disableSudoPassword "${username}"
addSSHKey "${username}" "${sshKey}"
changeSSHConfig
setupUfw
setupSwap
setTimezone "Asia/Singapore"
configureNTP

sudo service ssh restart

cleanup