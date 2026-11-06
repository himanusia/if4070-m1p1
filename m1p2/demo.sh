#!/bin/sh
# Print every CQ case answer, then exit.
cd "$(dirname "$0")" || exit 1

if ! command -v swipl >/dev/null 2>&1; then
    echo "SWI-Prolog >= 9 belum terpasang."
    echo "  macOS : brew install swi-prolog"
    echo "  Ubuntu: sudo add-apt-repository ppa:swi-prolog/stable && sudo apt install swi-prolog"
    exit 1
fi

exec swipl -q src/main.pl
