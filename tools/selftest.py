#!/usr/bin/env python3
"""Self-test untuk tools/validate.py.

Bangun domain dummy (perpustakaan) di direktori sementara dengan SEMUA syarat
spek terpenuhi, lalu pastikan validator melaporkan 0 FAIL. Fixture ini bukan isi
tugas siapa pun: tujuannya cuma membuktikan checker tidak salah tuduh (false
negative) dan tidak buta terhadap fitur yang seharusnya terdeteksi.

Jalankan: make selftest
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from rdflib import Graph, Literal, Namespace, RDF, RDFS, BNode
from rdflib.collection import Collection

REPO = Path(__file__).resolve().parent.parent

NS = "http://example.org/uji#"
OWL = Namespace("http://www.w3.org/2002/07/owl#")
XSD = Namespace("http://www.w3.org/2001/XMLSchema#")
EX = Namespace(NS)

KELAS = [
    "Perpustakaan", "Koleksi", "Buku", "Majalah", "Naskah", "Salinan", "Rak",
    "Anggota", "AnggotaAktif", "AnggotaDiblokir", "Pustakawan", "KepalaPustakawan",
    "Peminjaman", "PeminjamanTerlambat", "Pengembalian", "Denda", "DendaLunas",
    "DendaBelumLunas", "Kategori", "KategoriFiksi", "KategoriNonFiksi", "Penerbit",
    "Penulis", "Terbitan", "Edisi", "Lokasi", "Gedung", "Lantai", "JamOperasional",
    "KartuAnggota", "Sanksi", "PekanLiterasi",
]

PROPERTI_OBJEK = [
    "meminjam", "dipinjamOleh", "anggotaDari", "punyaSalinan", "punyaEdisi",
    "membawahi", "terdampakSanksi", "berlokasiDi", "mengarang", "diterbitkanOleh",
]
PROPERTI_DATA = ["jumlahDenda", "hariTerlambat", "tahunTerbit", "nomorKartu"]

TABEL = """# uji

## Tabel Aturan

| ID | Aturan | Sumber | Catatan |
|---|---|---|---|
| R1 | Setiap peminjaman mengacu tepat satu salinan koleksi | S1 |  |
| R2 | Anggota aktif adalah anggota yang tidak sedang diblokir | S1 |  |
| R3 | Denda muncul jika pengembalian melewati batas hari pinjam | S1 |  |
| R4 | Peminjaman terlambat adalah peminjaman yang punya denda | S2 |  |
| R5 | Kewenangan membawahi bersifat transitif | S2 |  |
| R6 | Kepala pustakawan adalah pustakawan yang membawahi minimal dua pustakawan | S2 |  |
| R7 | Naskah terbitan sebelum 1950 tergolong langka | S3 |  |
| R8 | Kategori fiksi dan non-fiksi saling lepas | S1 |  |
| R9 | Denda total adalah jumlah denda tiap hari keterlambatan | S3 | non-OWL |
| R10 | Anggota bebas tanggungan hanya jika tidak ada denda belum dibayar | S3 | non-OWL |
| R11 | House rule: denda dibebaskan pada pekan literasi | S3 | non-OWL, twist |
| R12 | Peminjaman hanya boleh diperpanjang sekali | S1 |  |

## Tabel Competency Question

| ID | Pertanyaan | Jawaban | Aturan |
|---|---|---|---|
| CQ1 | Apakah naskah terbitan 1948 tergolong langka? | Ya | R7 |
| CQ2 | Berapa denda total peminjaman yang terlambat tiga hari? | Tiga kali denda harian | R9, R3 |
| CQ3 | Apakah anggota dengan denda belum lunas bisa disebut bebas tanggungan? | Tidak | R10, R9, R3 |
| CQ4 | Apakah peminjaman berdenda tergolong peminjaman terlambat? | Ya | R4, R3 |
| CQ5 | Apakah anggota yang diblokir tergolong anggota aktif? | Tidak | R2, R8 |
| CQ6 | Apakah kepala pustakawan membawahi pustakawan? | Ya | R6, R5 |
| CQ7 | Apakah denda dibebaskan pada pekan literasi? | Ya | R11, R3 |
| CQ8 | Apakah perpanjangan kedua sah? | Tidak | R12, R1 |
"""


def build_ontology(path: Path) -> None:
    g = Graph()
    g.bind("ex", EX)
    g.add((EX[""], RDF.type, OWL.Ontology))

    for nama in KELAS:
        g.add((EX[nama], RDF.type, OWL.Class))
        g.add((EX[nama], RDFS.comment, Literal("Kelas uji, dasar R1")))

    for p in PROPERTI_OBJEK:
        g.add((EX[p], RDF.type, OWL.ObjectProperty))
    for p in PROPERTI_DATA:
        g.add((EX[p], RDF.type, OWL.DatatypeProperty))

    # --- disjointness (R8)
    g.add((EX.KategoriFiksi, OWL.disjointWith, EX.KategoriNonFiksi))
    g.add((EX.AnggotaAktif, OWL.disjointWith, EX.AnggotaDiblokir))

    # --- invers + transitif + rantai properti (R5)
    g.add((EX.meminjam, OWL.inverseOf, EX.dipinjamOleh))
    g.add((EX.membawahi, RDF.type, OWL.TransitiveProperty))
    chain = BNode()
    Collection(g, chain, [EX.meminjam, EX.anggotaDari])
    g.add((EX.terdampakSanksi, OWL.propertyChainAxiom, chain))

    def restr(on_prop, kind, filler) -> BNode:
        r = BNode()
        g.add((r, RDF.type, OWL.Restriction))
        g.add((r, OWL.onProperty, on_prop))
        g.add((r, kind, filler))
        return r

    def interaksi(a, b) -> BNode:
        node = BNode()
        lst = BNode()
        g.add((node, OWL.intersectionOf, lst))
        Collection(g, lst, [a, b])
        return node

    # --- kelas terdefinisi 1 (R2): AnggotaAktif ≡ Anggota ⊓ ¬AnggotaDiblokir
    comp = BNode()
    g.add((comp, RDF.type, OWL.Class))
    g.add((comp, OWL.complementOf, EX.AnggotaDiblokir))
    g.add((EX.AnggotaAktif, OWL.equivalentClass, interaksi(EX.Anggota, comp)))

    # --- kelas terdefinisi 2 (R4): PeminjamanTerlambat ≡ Peminjaman ⊓ ∃jumlahDenda.xsd:decimal
    g.add((EX.PeminjamanTerlambat, OWL.equivalentClass,
           interaksi(EX.Peminjaman, restr(EX.jumlahDenda, OWL.someValuesFrom, XSD.decimal))))

    # --- kelas terdefinisi 3: Edisi ≡ ∃punyaSalinan.Salinan
    g.add((EX.Edisi, OWL.equivalentClass,
           restr(EX.punyaSalinan, OWL.someValuesFrom, EX.Salinan)))

    # --- kelas terdefinisi 4 (R7): NaskahLangka ≡ Naskah ⊓ ∃tahunTerbit.xsd:integer
    g.add((EX.Koleksi, RDFS.subClassOf, EX.Koleksi))
    g.add((EX.NaskahLangka, RDF.type, OWL.Class))
    g.add((EX.NaskahLangka, RDFS.comment, Literal("R7")))
    g.add((EX.NaskahLangka, OWL.equivalentClass,
           interaksi(EX.Naskah, restr(EX.tahunTerbit, OWL.someValuesFrom, XSD.integer))))

    # --- kardinalitas tepat 1 (R1): Peminjaman ⊑ ∃=1 meminjam.Salinan
    r = BNode()
    g.add((EX.Peminjaman, RDFS.subClassOf, r))
    g.add((r, RDF.type, OWL.Restriction))
    g.add((r, OWL.onProperty, EX.meminjam))
    g.add((r, OWL.qualifiedCardinality, Literal(1)))
    g.add((r, OWL.onClass, EX.Salinan))

    # --- KepalaPustakawan ⊑ ∃membawahi.Pustakawan  (konteks R6)
    g.add((EX.KepalaPustakawan, OWL.equivalentClass,
           interaksi(EX.Pustakawan, restr(EX.membawahi, OWL.someValuesFrom, EX.Pustakawan))))

    # --- individu (5)
    for ind, cls in [
        ("budi", "Anggota"), ("siti", "Anggota"), ("buku1", "Buku"),
        ("pinjam1", "Peminjaman"), ("kopi", "Salinan"),
    ]:
        g.add((EX[ind], RDF.type, OWL.NamedIndividual))
        g.add((EX[ind], RDF.type, EX[cls]))
        g.add((EX[ind], RDFS.comment, Literal("Individu uji R1")))

    g.serialize(destination=str(path), format="xml")


def main() -> int:
    tmp = Path(tempfile.mkdtemp(prefix="if4070-selftest-"))
    for d in ("aturan", "sumber", "ontologi", "laporan"):
        (tmp / d).mkdir()

    cfg = (REPO / "config.yaml").read_text().replace('grup: "K11"', 'grup: "K99"')
    (tmp / "config.yaml").write_text(cfg)
    (tmp / "aturan" / "daftar-aturan.md").write_text(TABEL, encoding="utf-8")
    for n in ("S1_buku.pdf", "S2_wiki.pdf", "S3_house.pdf"):
        (tmp / "sumber" / n).write_bytes(b"%PDF-1.4 uji\n")

    build_ontology(tmp / "ontologi" / "K99_M1P1_ontologi.owl")
    shutil.copy(
        tmp / "ontologi" / "K99_M1P1_ontologi.owl",
        tmp / "ontologi" / "K99_M1P1_ontologi_inkonsisten.owl",
    )

    env = dict(os.environ, IF4070_ROOT=str(tmp))
    proc = subprocess.run(
        [sys.executable, str(REPO / "tools" / "validate.py")],
        env=env, capture_output=True, text=True,
    )
    print(proc.stdout)

    if proc.returncode != 0:
        print(f"SELFTEST GAGAL: fixture seharusnya lolos. Ada di {tmp}")
        return 1

    shutil.rmtree(tmp)
    print("SELFTEST LULUS: fixture lengkap -> 0 FAIL")
    return 0


if __name__ == "__main__":
    sys.exit(main())
