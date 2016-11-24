#!/bin/bash

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo ${current_dir}
}

current_dir=$(getCurrentDir)
source "${current_dir}/lib/BashScriptTestingLibrary.shl"
source "${current_dir}/../setupLibrary.sh"

test_user_account=testuser3
test_account_password="123%pass_321"

### Unit Tests ###

function testSetup () {
    echo "Test Setup"
    addUserAccount ${test_user_account} ${test_account_password} true
}

function testUserAccountCreated() {
    local user_exists_code=$(id -u ${test_user_account} > /dev/null 2>&1; echo $?)
    assertEquals 0 ${user_exists_code}
}

function testIfUserIsSudo() {
    local user_access=$(sudo -l -U ${test_user_account})
    assertContains "(ALL : ALL) ALL" "${user_access}"
}

function testAddingOfSSHKey() {
    disableSudoPassword

    local dummy_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBGTO0tsVejssuaYR5R3Y/i73SppJAhme1dH7W2c47d4gOqB4izP0+fRLfvbz/tnXFz4iOP/H6eCV05hqUhF+KYRxt9Y8tVMrpDZR2l75o6+xSbUOMu6xN+uVF0T9XzKcxmzTmnV7Na5up3QM3DoSRYX/EP3utr2+zAqpJIfKPLdA74w7g56oYWI9blpnpzxkEd3edVJOivUkpZ4JoenWManvIaSdMTJXMy3MtlQhva+j9CgguyVbUkdzK9KKEuah+pFZvaugtebsU+bllPTB0nlXGIJk98Ie9ZtxuY3nCKneB+KjKiXrAvXUPCI9mWkYS/1rggpFmu3HbXBnWSUdf localuser@machine.local"
    addSSHKey "${test_user_account}" "${dummy_key}"

    local ssh_file="$(sudo cat /home/${test_user_account}/.ssh/authorized_keys)"
    assertEquals "${ssh_file}" "${dummy_key}"
}

function testTeardown () {
    echo "Test Teardown"
    deleteTestUser
    revertSudoers
}

### Helper Functions ###

function deleteTestUser() {
    sudo deluser ${test_user_account} sudo
    sudo deluser -f --remove-home ${test_user_account}
}

function revertSudoers() {
    sudo cp /etc/sudoers.bak /etc/sudoers
    sudo rm -rf sudoers.bak
}

function disableSudoPassword() {
    sudo cp /etc/sudoers /etc/sudoers.bak
    sudo bash -c "echo '${test_user_account} ALL=(ALL) NOPASSWD: ALL' | (EDITOR='tee -a' visudo)"
}

runUnitTests