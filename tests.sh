#!/bin/bash

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo ${current_dir}
}

current_dir=$(getCurrentDir)
source "${current_dir}/BashScriptTestingLibrary.shl"
source "${current_dir}/../setupLibrary.sh"

test_user_account=testuser3

function testSetup () {
    echo "Test Setup"
    addUserAccount ${test_user_account} true
}

function testUserAccountCreated() {
    local user_exists_code=$(id -u ${test_user_account} > /dev/null 2>&1; echo $?)
    assertEquals 0 ${user_exists_code}
}

function testIfUserIsSudo() {
    # local user_access="$(sudo -l -U ${test_user_account})"
    # case "$user_access" in
    #     **)
    #     echo 'yes'
    #     ;;
    # esac
    # # $user_access=$(echo $user_access)
    # # local user_access=$(sudo -l -U ${test_user_account} > /dev/null 2>&1; echo $?);
    # # assertEquals 10 10
    # echo $user_access
    
    local sudoers=$(getent group sudo | cut -d: -f4)

    echo $sudoers
    echo $(printf -- '%s' "$sudoers" | egrep -q -- "${test_user_account}")
}

function testTeardown () {
    echo "Test Teardown"
    sudo deluser ${test_user_account} sudo
    sudo deluser -f --remove-home ${test_user_account}
}

runUnitTests