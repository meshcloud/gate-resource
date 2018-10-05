#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

shopt -s nullglob

doc() {
    cat <<-EOF
Processes all autoclose gates in a gate-repository

USAGE:
   autoclose [path]

EXAMPLES:
    autoclose gate-repository/my-autogate
EOF
}

main() {
    local path
    path="$1"
    # strip version numbers from all file names

    for autoclose in $path/*.autoclose; do
        echo "autoclose processing: $autoclose"
        passed=true
        echo "----------------------"
        while IFS="" read -r p || [ -n "$p" ]
        do
          echo -n "- testing $p: "
          if [[ ! -e "$path/$p" ]]; then
            echo "fail"
            passed=false
            break;
          fi;
          echo "ok"
        done < "$autoclose"

        if [ $passed = true ]; then 
          echo "autoclosing $autoclose"
          mv "$autoclose" "${autoclose//\.autoclose/}"
        fi
    done
}

if [[ $# == 1 ]]; then
    main "$@"
    exit 0;
else
    doc
    exit 1;
fi
