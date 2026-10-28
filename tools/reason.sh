#!/usr/bin/env bash
# Jalankan HermiT lewat ROBOT, headless, tanpa buka Protege.
#   bash tools/reason.sh <file.owl> consistent|inconsistent
#
# Java dan ROBOT ditemukan otomatis. Override lewat environment:
#   JAVA_BIN=/path/to/java ROBOT=/path/robot.jar bash tools/reason.sh ...
set -uo pipefail

FILE="${1:?pakai: reason.sh <file.owl> consistent|inconsistent}"
EXPECT="${2:-consistent}"

cari_java() {
  if [ -n "${JAVA_BIN:-}" ] && [ -x "$JAVA_BIN" ]; then echo "$JAVA_BIN"; return; fi
  if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then echo "$JAVA_HOME/bin/java"; return; fi
  local jh c
  jh="$(/usr/libexec/java_home 2>/dev/null)" && [ -x "$jh/bin/java" ] && { echo "$jh/bin/java"; return; }
  for c in "$HOME"/.hermes/tools/jdk/*/Contents/Home/bin/java \
           /opt/homebrew/opt/openjdk*/bin/java \
           /usr/local/opt/openjdk*/bin/java; do
    [ -x "$c" ] && { echo "$c"; return; }
  done
  command -v java 2>/dev/null
}

cari_robot() {
  if [ -n "${ROBOT:-}" ] && [ -f "$ROBOT" ]; then echo "$ROBOT"; return; fi
  local c
  for c in "$HOME"/.hermes/tools/robot.jar \
           "$HOME"/.hermes/tools/*/robot.jar \
           "$HOME/.local/share/robot.jar"; do
    [ -f "$c" ] && { echo "$c"; return; }
  done
}

JAVA="$(cari_java)"
ROBOT_FILE="$(cari_robot)"

if [ ! -f "$FILE" ]; then
  echo "FAIL berkas tidak ada: $FILE"
  exit 1
fi
if [ -z "$ROBOT_FILE" ]; then
  echo "FAIL robot.jar tidak ketemu. Set ROBOT=/path/robot.jar"
  exit 1
fi
if [ -z "$JAVA" ] || [ ! -x "$JAVA" ]; then
  echo "FAIL java tidak ketemu. Set JAVA_HOME=/path/to/jdk"
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

"$JAVA" -jar "$ROBOT_FILE" reason \
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
