#!/usr/bin/env bash
set -euo pipefail

# Execute tests from the directory that which contains the script
cd "$(dirname "$0")"

trap_exit () {
    echo "A command run from this script failed !"
}

trap trap_exit ERR

alias cat=../../bin/cat

diff -u <(cat -TE <(printf 'ab\tc\n') <(printf 'bruh\t\n\n\n')) <(cat <<EOF
ab^Ic$
bruh^I$
$
$
EOF
                                                                  )
diff -u <(cat <(printf 'ab\tc\n') <(printf 'bruh\t\n\n\n')) <(cat <<EOF
ab	c
bruh	


EOF
                                                                  )
