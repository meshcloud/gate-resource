#!/bin/bash

set -e

$(dirname $0)/in.sh
$(dirname $0)/check.sh
$(dirname $0)/out.sh

echo -e '\e[32mall tests passed!\e[0m'
