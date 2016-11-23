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

read -p "Enter the username of the new user account:" username
read -s -p "Enter new UNIX password:" password
printf "\n"
read -s -p "Retype new UNIX password:" password_confirmation
printf "\n"

if [[ "${password}" != "${password_confirmation}" ]]; then
    echo "Passwords do not match!"
    exit 1
fi

addUserAccount "${username}" "${password}"

read -rp $'Paste in the public SSH key for the new user:\n' sshKey
addSSHKey "${username}" "${sshKey}"