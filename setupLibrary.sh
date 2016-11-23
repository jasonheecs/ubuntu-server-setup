#!/bin/bash

function addUserAccount() {
    local username=${1}

    if [ ${2} == "true" ]; then
        sudo adduser --disabled-password --gecos '' ${username}
    else
        sudo adduser ${username}
    fi

    sudo usermod -aG sudo ${username}
}