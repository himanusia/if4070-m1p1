#!/bin/sh
# Jalankan seluruh 12 CQ tanpa masuk mode interaktif.
cd "$(dirname "$0")" || exit 1

if ! command -v swipl >/dev/null 2>&1; then
    echo "SWI-Prolog belum terpasang. Jalankan: brew install swi-prolog"
    exit 1
fi

exec swipl -q src/main.pl
