#!/bin/bash
set -e
function abs_dir() {
  (cd "$1" && echo "$(pwd)")
}
bdir="$(abs_dir ${BASH_SOURCE%/*})"

script="$bdir/check-windows-dep-aslr"
file="$1"

if [ $(uname.exe -o) = 'Cygwin' ]
then
  script=$(cygpath -aw "$script")
  file=$(cygpath -aw "$file")
fi
exec "$bdir/../virtualenv-pefile/Scripts/python.exe" "$script" "$file"
