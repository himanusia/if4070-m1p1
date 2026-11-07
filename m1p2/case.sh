#!/bin/sh
# Show one CQ case: loads kb.pl only, injects that case's facts, prints proof.
# Usage: ./case.sh CQ8
cd "$(dirname "$0")" || exit 1

if [ -z "$1" ]; then
    echo "Usage: ./case.sh <CASE_ID>    e.g. ./case.sh CQ8"
    echo "Cases:"
    swipl -q -g "use_module(library(json)),open('test/cq.json',read,S,[encoding(utf8)]),json_read_dict(S,L),close(S),forall(member(K,L),(print(K.id),print(' '))),nl,halt"
    exit 1
fi

exec swipl -q -s test/case.pl -- "$@"
