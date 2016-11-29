#!/bin/bash

set -ex

####
#   Loop through all the Vagrantfiles in the /Vagrant dir and run the unit tests (unit-tests.sh) against them
#   Test results are stored in the /results dir
###

function getCurrentDir() {
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo ${current_dir}
}

function runUnitTest() {
    local results_filename=${1}

    vagrant up
    vagrant ssh -c "cd /vagrant/tests; bash unit-tests.sh > results/${results_filename}.txt 2>&1"
    vagrant destroy -f
    rm -rf "Vagrantfile"
}

current_dir=$(getCurrentDir)

for file in "${current_dir}"/Vagrant/*; do
    filename=$(basename "${file}")
    cp "${current_dir}/Vagrant/${filename}" "${current_dir}/../Vagrantfile"
    cd "${current_dir}/../"
    runUnitTest "${filename}"
done
