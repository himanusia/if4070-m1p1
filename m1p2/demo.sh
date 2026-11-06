#!/bin/sh
# Print all twelve CQ answers, then exit.
cd "$(dirname "$0")" || exit 1

if ! command -v swipl >/dev/null 2>&1; then
    echo "SWI-Prolog not installed. Run: brew install swi-prolog"
    exit 1
fi

exec swipl -q src/main.pl
