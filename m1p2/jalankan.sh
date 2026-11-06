#!/bin/sh
# Buka sesi Prolog interaktif dengan kb.pl dan abox.pl sudah dimuat.
cd "$(dirname "$0")" || exit 1

if ! command -v swipl >/dev/null 2>&1; then
    echo "SWI-Prolog belum terpasang. Jalankan: brew install swi-prolog"
    exit 1
fi

cat <<'PESAN'

  KB mahjong K11 siap. Contoh kueri, salin salah satu:

    classify(tangan_cq8, winning_hand).
    explain(classify(tangan_cq8, winning_hand), B).
    why_not(classify(tangan_tanpa_yaku, winning_hand), A).
    halt.

PESAN

exec swipl -q src/kb.pl src/abox.pl
