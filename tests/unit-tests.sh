#!/bin/bash

set -e

while getopts "s" opt; do
    case $opt in
    s) SKIP_SETUP=true ;;
    *) echo "usage: $0 [-v] [-r]" >&2
       exit 1 ;;
    esac
done

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo "${current_dir}"
}

current_dir=$(getCurrentDir)
# shellcheck source=/dev/null
source "${current_dir}/lib/bunit.shl"
# shellcheck source=/dev/null
source "${current_dir}/../setupLibrary.sh"

test_user_account=testuser

# shellcheck disable=SC2034
VERBOSE_MODE="true"

### Unit Tests ###

function testSetup () {
    echo "Test Setup"
    addUserAccount ${test_user_account} true
}

function testUserAccountCreated() {
    local user_exists_code
    user_exists_code="$(id -u ${test_user_account} > /dev/null 2>&1; echo $?)"
    assertEquals 0 "${user_exists_code}"
}

function testIfUserIsSudo() {
    if [[ $SKIP_SETUP != true ]]; then
        local user_access
        user_access="$(sudo -l -U ${test_user_account})"
        assertContains "(ALL : ALL) ALL" "${user_access}"
    fi
}

function testAddingOfSSHKey() {
    if [[ $SKIP_SETUP != true ]]; then
        disableSudoPassword "${test_user_account}"

        local dummy_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBGTO0tsVejssuaYR5R3Y/i73SppJAhme1dH7W2c47d4gOqB4izP0+fRLfvbz/tnXFz4iOP/H6eCV05hqUhF+KYRxt9Y8tVMrpDZR2l75o6+xSbUOMu6xN+uVF0T9XzKcxmzTmnV7Na5up3QM3DoSRYX/EP3utr2+zAqpJIfKPLdA74w7g56oYWI9blpnpzxkEd3edVJOivUkpZ4JoenWManvIaSdMTJXMy3MtlQhva+j9CgguyVbUkdzK9KKEuah+pFZvaugtebsU+bllPTB0nlXGIJk98Ie9ZtxuY3nCKneB+KjKiXrAvXUPCI9mWkYS/1rggpFmu3HbXBnWSUdf localuser@machine.local"
        addSSHKey "${test_user_account}" "${dummy_key}"

        local ssh_file
        ssh_file="$(sudo cat /home/${test_user_account}/.ssh/authorized_keys)"
        assertEquals "${ssh_file}" "${dummy_key}"
    fi
}

function testChangeSSHConfig() {
    if [[ $SKIP_SETUP != true ]]; then
        changeSSHConfig

        local ssh_config
        ssh_config="$(sudo cat /etc/ssh/sshd_config)"
        assertContains "PasswordAuthentication no" "${ssh_config}"
        assertContains "PermitRootLogin no" "${ssh_config}"
    fi
}

function testUfw() {
    setupUfw

    local ufw_status
    ufw_status="$(sudo ufw status)"
    assertContains "Status: active" "${ufw_status}"
    assertContains "OpenSSH" "${ufw_status}"
}

function testSwap() {
    createSwap

    assertContains "/swapfile" "$(ls -lh /swapfile)"
    assertContains "/swapfile" "$(sudo swapon -s)"
}

function testSwapSettings() {
    local swappiness
    local cache_pressure

    swappiness="$(cat /proc/sys/vm/swappiness)"
    cache_pressure="$(cat /proc/sys/vm/vfs_cache_pressure)"
    
    tweakSwapSettings 10 50

    assertEquals "10" "$(cat /proc/sys/vm/swappiness)"
    assertEquals "50" "$(cat /proc/sys/vm/vfs_cache_pressure)"

    tweakSwapSettings "${swappiness}" "${cache_pressure}"
}

function testTimezone() {
    local timezone
    timezone="$(cat /etc/timezone)"

    setTimezone "America/New_York"
    assertEquals "America/New_York" "$(cat /etc/timezone)"
    setTimezone "${timezone}"
}

function testNTP() {
    configureNTP
    ubuntu_version="$(lsb_release -sr)"

    if [[ $(bc -l <<< "${ubuntu_version} >= 18.04") -eq 1 ]]; then
        sleep 2
        assertContains "System clock synchronized: yes" "$(timedatectl status)"
    else
        assertContains "NTP synchronized: yes" "$(timedatectl status)"
    fi
}

function testTeardown () {
    echo "Test Teardown"

    deleteTestUser

    if [[ $SKIP_SETUP != true ]]; then
        revertSudoers
        revertSSHConfig
    fi
    
    revertUfw
    deleteSwap

    sudo apt-get --purge --assume-yes autoremove ntp
}

### Helper Functions ###

function deleteTestUser() {
    sudo deluser ${test_user_account} sudo
    sudo deluser -f --remove-home ${test_user_account}
}

function revertSSHConfig() {
    sudo cp /etc/ssh/sshd_config.old /etc/ssh/sshd_config
    sudo rm -rf /etc/ssh/sshd_config.old
}

function revertUfw() {
    sudo ufw delete allow OpenSSH
    sudo ufw disable
}

function deleteSwap() {
    sudo swapoff /swapfile
    sudo rm /swapfile
}

runUnitTests