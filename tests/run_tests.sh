#!/usr/bin/env bash
set -euo pipefail

# Execute tests from the directory that which contains the script
cd "$(dirname "$0")"

trap_exit () {
    echo "A command run from this script failed !"
}

trap trap_exit ERR

for i in ./mv/FreeBSD-legacy_test.sh ./cat/my_tests.sh
do
    eval "$i" || echo "Test '$i' failed" &
done

# Wait for all tests to be over before exiting
wait

