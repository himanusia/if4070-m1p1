#!/usr/bin/env python3
"""Bikin KXX_M1P1.zip sesuai struktur deliverable.

Isi zip:
  KXX_M1P1_ontologi.owl
  KXX_M1P1_ontologi_inkonsisten.owl
  KXX_M1P1_Sumber/            (isi folder sumber/, tanpa README)
  KXX_M1P1_Laporan.pdf

Menolak jalan kalau nama grup masih KXX, ada berkas wajib yang hilang,
atau ukuran melewati 25 MB.
"""

from __future__ import annotations

import os
import shutil
import sys
import zipfile
from pathlib import Path

import yaml

ROOT = Path(
    os.environ.get("IF4070_ROOT", str(Path(__file__).resolve().parent.parent))
)
BUILD = ROOT / "build"
MAX_BYTES = 25 * 1024 * 1024


def main() -> int:
    cfg = yaml.safe_load((ROOT / "config.yaml").read_text(encoding="utf-8"))
    grup = str(cfg.get("grup", "KXX")).strip()

    if not grup or grup == "KXX":
        print("FAIL config.yaml grup masih 'KXX'. Isi nomor kelompok dulu.")
        return 1

    ont = ROOT / "ontologi" / f"{grup}_M1P1_ontologi.owl"
    bad = ROOT / "ontologi" / f"{grup}_M1P1_ontologi_inkonsisten.owl"
    pdf = ROOT / "laporan" / "laporan.pdf"
    sumber = ROOT / "sumber"

    missing = [p.relative_to(ROOT) for p in (ont, bad, pdf) if not p.exists()]
    if missing:
        print("FAIL berkas wajib hilang: " + ", ".join(str(m) for m in missing))
        print("     ontologi  -> buat di Protege dengan nama persis seperti di atas")
        print("     laporan   -> make report")
        return 1

    src_files = [
        p for p in sorted(sumber.glob("*")) if p.is_file() and p.name != "README.md"
    ] if sumber.exists() else []
    if not src_files:
        print("FAIL folder sumber/ kosong. Setiap kode S1, S2, ... butuh berkas.")
        return 1

    if BUILD.exists():
        shutil.rmtree(BUILD)
    stage = BUILD / "stage"
    stage.mkdir(parents=True)

    shutil.copy2(ont, stage / f"{grup}_M1P1_ontologi.owl")
    shutil.copy2(bad, stage / f"{grup}_M1P1_ontologi_inkonsisten.owl")
    shutil.copy2(pdf, stage / f"{grup}_M1P1_Laporan.pdf")
    dest = stage / f"{grup}_M1P1_Sumber"
    dest.mkdir()
    for f in src_files:
        shutil.copy2(f, dest / f.name)

    zip_path = ROOT / f"{grup}_M1P1.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for p in sorted(stage.rglob("*")):
            if p.is_file():
                z.write(p, p.relative_to(stage))

    size = zip_path.stat().st_size
    if size > MAX_BYTES:
        print(f"FAIL {zip_path.name} {size / 1e6:.1f} MB, batas 25 MB")
        print("     Pindahkan dokumen sumber terbesar ke Drive, tautkan di laporan.")
        return 1

    print(f"siap      : {zip_path.name} ({size / 1e6:.2f} MB)")
    with zipfile.ZipFile(zip_path) as z:
        for info in z.infolist():
            print(f"            {info.file_size / 1e3:9.1f} kB  {info.filename}")

    # sanity: pastikan ontologi masih valid RDF/XML
    try:
        from rdflib import Graph

        Graph().parse(str(ont), format="xml")
        print("cek       : ontologi utama terparse sebagai RDF/XML")
    except Exception as e:  # noqa: BLE001
        print(f"WARN      : gagal parse ontologi ({e})")

    print("\nYang mengumpulkan: NIM terkecil. Batas: Kamis 29 Okt 2026, 17.59 WIB.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
