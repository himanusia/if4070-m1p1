#!/usr/bin/env bash
# Jalankan HermiT lewat ROBOT, headless, tanpa buka Protege.
#   bash tools/reason.sh <file.owl> consistent|inconsistent
# ROBOT exit != 0 kalau hasil reasoner tidak sesuai harapan.
set -uo pipefail

FILE="${1:?pakai: reason.sh <file.owl> consistent|inconsistent}"
EXPECT="${2:-consistent}"

JAVA_HOME="${JAVA_HOME:-$HOME/.hermes/tools/jdk/jdk-21.0.13+9/Contents/Home}"
JAVA="$JAVA_HOME/bin/java"
ROBOT="${ROBOT:-$HOME/.hermes/tools/robot.jar}"

if [ ! -f "$FILE" ]; then
  echo "FAIL berkas tidak ada: $FILE"
  exit 1
fi
if [ ! -f "$ROBOT" ]; then
  echo "FAIL robot.jar tidak ada di $ROBOT"
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

"$JAVA" -jar "$ROBOT" reason \
  --input "$FILE" \
  --reasoner HermiT \
  --equivalent-classes-allowed all \
  --output "$TMP/out.owl" >"$TMP/log" 2>&1
CODE=$?

if grep -qiE "inconsistent|inconsistency" "$TMP/log"; then
  ACTUAL="inconsistent"
elif [ $CODE -eq 0 ]; then
  ACTUAL="consistent"
else
  echo "FAIL reasoner gagal dijalankan (exit $CODE):"
  sed 's/^/     /' "$TMP/log" | tail -20
  exit 1
fi

if [ "$ACTUAL" = "$EXPECT" ]; then
  echo "OK   $(basename "$FILE") -> $ACTUAL (HermiT, sesuai harapan)"
  exit 0
fi

echo "FAIL $(basename "$FILE") -> $ACTUAL, tapi diharapkan $EXPECT"
if [ "$EXPECT" = "inconsistent" ]; then
  echo "     Salinan inkonsisten belum benar-benar kontradiktif."
  echo "     Contoh: individu diklaim milik dua kelas disjoint."
else
  echo "     Ontologi utama tidak konsisten. Lihat penjelasan di bawah:"
  grep -iE "explanation|inconsistent|error" -A4 "$TMP/log" | sed 's/^/     /' | head -30
fi
exit 1
