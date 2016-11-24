#!/bin/bash

function addUserAccount() {
    local username=${1}
    local password=${2}
    local silent_mode=${3}

    if [[ ${silent_mode} == "true" ]]; then
        sudo adduser --disabled-password --gecos '' ${username}
    else
        sudo adduser --disabled-password ${username}
    fi

    echo "${username}:${password}" | sudo chpasswd
    sudo usermod -aG sudo ${username}
}

function addSSHKey() {
    local username=${1}
    local sshKey=${2}

    execAsUser "${username}" "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys"
    execAsUser "${username}" "echo \"${sshKey}\" | sudo tee -a ~/.ssh/authorized_keys"
    execAsUser "${username}" "chmod 600 ~/.ssh/authorized_keys"
}

function execAsUser() {
    local username=${1}
    local exec_command=${2}

    sudo -u "${username}" -H sh -c "${exec_command}"
}