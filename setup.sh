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

function hasSwap() {
    local swap_status=$(sudo swapon -s)

    if [[ "$(sudo swapon -s)" == *"/swapfile"* ]]; then
        echo "true"
    else
        echo "false"
    fi
}

function cleanup() {
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

function logTimestamp() {
    local filename=${1}
    echo "===================" >>"${filename}" 2>&1
    echo "Log generated on $(date)" >>"${filename}" 2>&1
    echo "===================" >>"${filename}" 2>&1
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
echo 'Running setup script...'
logTimestamp "output.log"
disableSudoPassword "${username}" >>output.log 2>&1
addSSHKey "${username}" "${sshKey}" >>output.log 2>&1
changeSSHConfig >>output.log 2>&1
setupUfw >>output.log 2>&1

if [[ $(hasSwap) == "false" ]]; then
    setupSwap >>output.log 2>&1
fi

setTimezone "Asia/Singapore" >>output.log 2>&1
configureNTP >>output.log 2>&1

sudo service ssh restart

cleanup

echo 'Setup Done! Log file is located at output.log'