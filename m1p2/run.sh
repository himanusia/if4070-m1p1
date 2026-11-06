#!/bin/sh
# Interactive session with kb.pl and abox.pl preloaded.
cd "$(dirname "$0")" || exit 1

if ! command -v swipl >/dev/null 2>&1; then
    echo "SWI-Prolog not installed. Run: brew install swi-prolog"
    exit 1
fi

cat <<'BANNER'

  K11 mahjong KB ready. Sample queries:

    classify(tangan_cq8, winning_hand).
    explain(classify(tangan_cq8, winning_hand), B).
    why_not(classify(tangan_tanpa_yaku, winning_hand), A).
    halt.

BANNER

exec swipl -q src/kb.pl src/abox.pl
