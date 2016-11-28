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

function changeSSHConfig() {
    sudo sed -re 's/^(\#?)(PasswordAuthentication)([[:space:]]+)yes/\2\3no/' -i.$(echo 'old') /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(PermitRootLogin)([[:space:]]+)(.*)/PermitRootLogin no/' -i /etc/ssh/sshd_config
}

function setupUfw() {
    sudo ufw allow OpenSSH
    yes y | sudo ufw enable
}

function createSwap() {
   local swapmem=$(($(getPhysicalMemory) * 2))

   # Anything over 4GB in swap is probably unnecessary as a RAM fallback
   if [[ ${swapmem} > 4 ]]; then
        phymem=4
   fi

   sudo fallocate -l ${swapmem}G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
}

function mountSwap() {
    sudo cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
}

function tweakSwapSettings() {
    local swappiness=${1}
    local vfs_cache_pressure=${2}

    sudo sysctl vm.swappiness=${swappiness}
    sudo sysctl vm.vfs_cache_pressure=${vfs_cache_pressure}
}

function saveSwapSettings() {
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
}

function getPhysicalMemory() {
    local phymem=$(free -g|awk '/^Mem:/{print $2}')
    if [[ ${phymem} == '0' ]]; then
        echo 1
    else
        echo ${phymem}
    fi
}