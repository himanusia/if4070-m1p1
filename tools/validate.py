#!/usr/bin/env python3
"""Validator syarat Milestone 1 Part 1 IF4070.

Yang dicek di sini hanya hal yang bisa diputuskan mesin: jumlah, penomoran,
kelengkapan berkas sumber, keberadaan fitur DL, dan penamaan deliverable.
Validator tidak menilai mutu penalaran, dan tidak menulis isi apa pun.

Exit code 0 kalau tidak ada FAIL. WARN tidak menggagalkan.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(
    os.environ.get("IF4070_ROOT", str(Path(__file__).resolve().parent.parent))
)
RULES_MD = ROOT / "aturan" / "daftar-aturan.md"
SUMBER_DIR = ROOT / "sumber"
LAPORAN_PDF = ROOT / "laporan" / "laporan.pdf"

RULES: list[tuple[str, str]] = []
WARNS: list[str] = []
SEEN: set[str] = set()


def ok(msg: str) -> None:
    print(f"  \033[32mOK\033[0m   {msg}")


def fail(msg: str, hint: str = "") -> None:
    RULES.append(("FAIL", msg))
    print(f"  \033[31mFAIL\033[0m {msg}")
    if hint:
        print(f"       -> {hint}")


def warn(msg: str) -> None:
    WARNS.append(msg)
    print(f"  \033[33mWARN\033[0m {msg}")


def head(title: str) -> None:
    print(f"\n\033[1m{title}\033[0m")


# --------------------------------------------------------------------------
# parsing markdown
# --------------------------------------------------------------------------

def split_row(line: str) -> list[str]:
    line = line.strip()
    if line.startswith("|"):
        line = line[1:]
    if line.endswith("|"):
        line = line[:-1]
    return [c.strip() for c in line.split("|")]


def parse_tables(text: str) -> list[tuple[list[str], list[list[str]]]]:
    """Kembalikan [(header, rows)] untuk setiap tabel markdown di teks."""
    tables: list[tuple[list[str], list[list[str]]]] = []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith("|") and i + 1 < len(lines) and re.match(
            r"^\|[\s:|-]+\|$", lines[i + 1].strip()
        ):
            header = [h.lower() for h in split_row(line)]
            rows: list[list[str]] = []
            j = i + 2
            while j < len(lines) and lines[j].strip().startswith("|"):
                cells = split_row(lines[j])
                if any(c for c in cells):
                    rows.append(cells)
                j += 1
            tables.append((header, rows))
            i = j
        else:
            i += 1
    return tables


def col(header: list[str], *names: str) -> int | None:
    for n in names:
        for idx, h in enumerate(header):
            if n in h:
                return idx
    return None


def cell(row: list[str], idx: int | None) -> str:
    if idx is None or idx >= len(row):
        return ""
    return row[idx].strip()


def clean(s: str) -> str:
    return s.replace("*", "").replace("`", "").strip()


# --------------------------------------------------------------------------
# tabel aturan
# --------------------------------------------------------------------------

def check_rules(cfg: dict) -> tuple[list[dict], list[dict]]:
    head("1. Tabel aturan")

    if not RULES_MD.exists():
        fail(f"{RULES_MD.relative_to(ROOT)} tidak ada")
        return [], []

    tables = parse_tables(RULES_MD.read_text(encoding="utf-8"))
    rule_rows: list[dict] = []
    cq_rows: list[dict] = []

    for header, rows in tables:
        if col(header, "pertanyaan") is not None:
            i_id, i_q = col(header, "id"), col(header, "pertanyaan")
            i_a, i_r = col(header, "jawaban"), col(header, "aturan")
            for r in rows:
                rid = clean(cell(r, i_id))
                if not re.fullmatch(r"CQ\d+", rid):
                    if any(c for c in r):
                        warn(f"baris CQ dilewati, ID tidak valid: {rid!r}")
                    continue
                cq_rows.append(
                    {
                        "id": rid,
                        "pertanyaan": cell(r, i_q),
                        "jawaban": cell(r, i_a),
                        "aturan": cell(r, i_r),
                    }
                )
        elif col(header, "sumber") is not None:
            i_id, i_r = col(header, "id"), col(header, "aturan")
            i_s, i_c = col(header, "sumber"), col(header, "catatan")
            for row in rows:
                raw_id = clean(cell(row, i_id))
                if not raw_id:
                    continue
                if re.search(r"\s", raw_id):
                    fail(
                        f"baris aturan punya lebih dari satu ID ({raw_id!r})",
                        "satu aturan = satu pernyataan, satu baris. Pecah jadi baris sendiri.",
                    )
                    continue
                if not re.fullmatch(r"R\d+", raw_id):
                    warn(f"baris aturan dilewati, ID tidak valid: {raw_id!r}")
                    continue
                rule_rows.append(
                    {
                        "id": raw_id,
                        "aturan": clean(cell(row, i_r)),
                        "sumber": clean(cell(row, i_s)),
                        "catatan": clean(cell(row, i_c)),
                    }
                )

    n = len(rule_rows)
    if n == 0:
        fail("tabel aturan kosong", "isi R1..Rn di aturan/daftar-aturan.md")
        return rule_rows, cq_rows

    two = cfg.get("jumlah_anggota", 3) == 2
    need = cfg["ambang"]["aturan_min_2_anggota" if two else "aturan_min"]
    label = "2 anggota" if two else "3 anggota"
    if n >= need:
        ok(f"{n} aturan (minimal {need} untuk {label})")
    else:
        fail(f"baru {n} aturan, minimal {need} untuk {label}")

    # penomoran berurutan
    nums = [int(r["id"][1:]) for r in rule_rows]
    if nums == list(range(1, n + 1)):
        ok("ID berurutan R1..R%d" % n)
    else:
        gaps = [f"R{i}" for i in range(1, max(nums) + 1) if i not in nums]
        fail(
            f"ID tidak berurutan (hilang: {', '.join(gaps) if gaps else '-'}, "
            f"duplikat/urutan: {nums})",
            "ID ditulis berurutan R1, R2, R3, ...",
        )

    # non-OWL
    non_owl = [r["id"] for r in rule_rows if "non-owl" in r["catatan"].lower()]
    need_non = cfg["ambang"]["non_owl_min"]
    if len(non_owl) >= need_non:
        ok(f"{len(non_owl)} aturan non-OWL ditandai: {', '.join(non_owl)}")
    else:
        fail(
            f"baru {len(non_owl)} aturan non-OWL, minimal {need_non}",
            "contoh yang sah: agregasi (rata-rata/jumlah), pengecualian, "
            "atau yang hanya benar di asumsi dunia tertutup. Tandai 'non-OWL' di kolom catatan.",
        )

    # twist
    twist = [r["id"] for r in rule_rows if "twist" in r["catatan"].lower()]
    if twist:
        ok(f"{len(twist)} aturan twist/house rules: {', '.join(twist)}")
    else:
        warn(
            "tidak ada aturan bertanda 'twist'. Kalau domainnya populer di internet, "
            "house rules bikin perbandingan RAG di Milestone 2 bermakna."
        )

    # aturan kosong & kalimat majemuk
    kosong_isi = [r["id"] for r in rule_rows if not r["aturan"]]
    kosong_src = [r["id"] for r in rule_rows if not r["sumber"]]
    if kosong_isi:
        fail(
            f"{len(kosong_isi)} aturan belum diisi pernyataannya: {', '.join(kosong_isi)}",
            "satu aturan = satu pernyataan yang bisa diuji benar atau salah.",
        )
    if kosong_src:
        fail(
            f"{len(kosong_src)} aturan belum diisi sumbernya: {', '.join(kosong_src)}",
            "setiap aturan harus bisa ditelusuri ke sumber (S1, S2, ...).",
        )
    for r in rule_rows:
        if not r["aturan"] or not r["sumber"]:
            continue
        if len(r["aturan"]) < 15:
            warn(f"{r['id']}: pernyataan sangat pendek ({r['aturan']!r}), cek apakah teruji benar/salah")
        if r["aturan"].lower().count(" dan ") >= 2:
            warn(
                f"{r['id']}: kemungkinan kalimat majemuk (>=2 'dan'). "
                "Satu aturan harus satu pernyataan yang bisa diuji."
            )

    # kode sumber -> berkas
    check_sources(rule_rows)
    return rule_rows, cq_rows


def check_sources(rule_rows: list[dict]) -> None:
    head("2. Dokumen sumber")

    codes: dict[str, list[str]] = {}
    for r in rule_rows:
        for code in re.findall(r"S\d+", r["sumber"]):
            codes.setdefault(code, []).append(r["id"])

    if not codes:
        fail("tidak ada kode sumber (S1, S2, ...) di kolom sumber")
        return

    if not SUMBER_DIR.exists():
        fail("folder sumber/ tidak ada")
        return

    files = [p.name for p in SUMBER_DIR.iterdir() if p.is_file() and p.name != "README.md"]
    for code in sorted(codes, key=lambda c: int(c[1:])):
        pattern = re.compile(rf"^{code}(?!\d)")
        hits = [f for f in files if pattern.match(f)]
        if hits:
            ok(f"{code} -> {', '.join(hits)} (dipakai {', '.join(sorted(set(codes[code])))})")
        else:
            fail(
                f"{code} dipakai aturan {', '.join(sorted(set(codes[code])))} "
                f"tapi tidak ada berkas di sumber/ yang diawali {code}",
                f"contoh nama: sumber/{code}_buku_panduan.pdf. Tautan saja tidak cukup.",
            )

    orphans = [
        f for f in files
        if not any(re.compile(rf"^{c}(?!\d)").match(f) for c in codes)
    ]
    if orphans:
        warn(f"berkas di sumber/ tanpa kode yang dipakai: {', '.join(sorted(orphans))}")


# --------------------------------------------------------------------------
# competency question
# --------------------------------------------------------------------------

def check_cq(cq_rows: list[dict], rule_rows: list[dict], cfg: dict) -> None:
    head("3. Tabel competency question")

    n = len(cq_rows)
    need = cfg["ambang"]["cq_min"]
    if n >= need:
        ok(f"{n} competency question (minimal {need})")
    else:
        fail(f"baru {n} CQ, minimal {need}")

    nums = [int(c["id"][2:]) for c in cq_rows]
    if nums and nums != list(range(1, n + 1)):
        fail(f"ID CQ tidak berurutan: {nums}")

    rule_ids = {r["id"] for r in rule_rows}
    non_owl = {r["id"] for r in rule_rows if "non-owl" in r["catatan"].lower()}

    referenced: set[str] = set()
    tanpa_aturan: list[str] = []
    tanpa_jawaban: list[str] = []
    for c in cq_rows:
        ids = set(re.findall(r"R\d+", c["aturan"]))
        referenced |= ids
        unknown = ids - rule_ids
        if unknown:
            fail(f"{c['id']} merujuk aturan yang tidak ada: {', '.join(sorted(unknown))}")
        if not ids:
            tanpa_aturan.append(c["id"])
        if not c["jawaban"]:
            tanpa_jawaban.append(c["id"])
    if tanpa_aturan:
        fail(
            f"{len(tanpa_aturan)} CQ belum menyebut aturan: {', '.join(tanpa_aturan)}",
            "setiap CQ harus menyebut aturan yang dipakai menjawab.",
        )
    if tanpa_jawaban:
        fail(
            f"{len(tanpa_jawaban)} CQ belum diisi jawabannya: {', '.join(tanpa_jawaban)}",
            "tulis jawaban akhirnya saja; jalur penalaran masuk laporan.",
        )

    # setiap non-OWL diuji minimal satu CQ
    untested = non_owl - referenced
    if untested:
        fail(
            f"aturan non-OWL belum diuji CQ mana pun: {', '.join(sorted(untested))}",
            "setiap aturan non-OWL diuji minimal satu competency question.",
        )
    elif non_owl:
        ok(f"semua aturan non-OWL terpakai di CQ: {', '.join(sorted(non_owl))}")

    # jawaban "tidak"
    negatives = [c["id"] for c in cq_rows if c["jawaban"].strip().lower().startswith("tidak")]
    need_neg = cfg["ambang"]["cq_jawaban_tidak_min"]
    if len(negatives) >= need_neg:
        ok(f"{len(negatives)} CQ berjawaban 'tidak': {', '.join(negatives)}")
    else:
        fail(
            f"baru {len(negatives)} CQ berjawaban 'tidak', minimal {need_neg}",
            "dipakai buat menguji penjelasan 'mengapa tidak' di Part 2.",
        )

    # rantai >= 3 aturan
    chains = [(c["id"], len(set(re.findall(r"R\d+", c["aturan"])))) for c in cq_rows]
    deep = [cid for cid, k in chains if k >= 3]
    if deep:
        best = max(chains, key=lambda x: x[1])
        ok(f"CQ dengan rantai >=3 aturan: {', '.join(deep)} (terdalam {best[0]}: {best[1]} aturan)")
    else:
        fail(
            "tidak ada CQ yang butuh rantai penalaran >=3 aturan",
            "gabungkan beberapa aturan dalam satu jalur inferensi, bukan satu CQ satu aturan.",
        )

    orphan_rules = rule_ids - referenced
    if orphan_rules:
        warn(f"aturan tidak dipakai CQ mana pun: {', '.join(sorted(orphan_rules, key=lambda s: int(s[1:])))}")


# --------------------------------------------------------------------------
# ontologi
# --------------------------------------------------------------------------

def check_ontology(cfg: dict) -> None:
    head("4. Ontologi")

    try:
        from rdflib import Graph, Namespace, RDF, RDFS
        from rdflib.term import BNode, Literal, URIRef
    except ImportError:
        fail("rdflib belum terpasang", "jalankan: make setup")
        return

    OWL = Namespace("http://www.w3.org/2002/07/owl#")
    XSD = Namespace("http://www.w3.org/2001/XMLSchema#")

    grup = cfg.get("grup", "KXX")
    ont = ROOT / "ontologi" / f"{grup}_M1P1_ontologi.owl"
    bad = ROOT / "ontologi" / f"{grup}_M1P1_ontologi_inkonsisten.owl"

    if grup == "KXX":
        warn("config.yaml masih 'KXX'. Ganti dengan nomor kelompok sebelum packaging.")
    for p, label in ((ont, "ontologi utama"), (bad, "salinan inkonsisten")):
        if not p.exists():
            fail(f"{label} tidak ada: {p.relative_to(ROOT)}")
    if not ont.exists():
        return

    g = Graph()
    try:
        g.parse(str(ont), format="xml")
    except Exception as e:  # noqa: BLE001
        fail(f"gagal parse {ont.name}: {e}", "format harus RDF/XML, bukan Turtle/OWL Functional")
        return
    ok(f"{ont.name} terparse sebagai RDF/XML ({len(g)} triple)")

    classes = sorted(
        {s for s in g.subjects(RDF.type, OWL.Class) if isinstance(s, URIRef)}
    )
    n = len(classes)
    lo, hi = cfg["ambang"]["kelas_min"], cfg["ambang"]["kelas_max"]
    if lo <= n <= hi:
        ok(f"{n} kelas (rentang {lo}-{hi})")
    elif n < lo:
        fail(f"baru {n} kelas, minimal {lo}", "tambah konsep, bukan menambah individu")
    else:
        fail(f"{n} kelas, maksimal {hi}", "ontologi lebih besar tidak dinilai lebih tinggi")

    # ---- fitur wajib ----
    head("5. Fitur logika deskripsi wajib")

    restrictions = set(g.subjects(RDF.type, OWL.Restriction))

    def memuat_restriksi(expr) -> bool:
        """True kalau ekspresi memuat owl:Restriction, baik langsung maupun di dalam
        intersectionOf/unionOf/complementOf. A ≡ B ⊓ ∃r.C itu bnode intersection,
        bukan bnode restriksi, jadi harus ditelusuri."""
        if not isinstance(expr, BNode):
            return False
        return any(
            p_ == RDF.type and o_ == OWL.Restriction
            for _, p_, o_ in g.cbd(expr)
        )

    defined: list[str] = []
    for c in classes:
        for expr in g.objects(c, OWL.equivalentClass):
            if memuat_restriksi(expr):
                defined.append(str(c).split("#")[-1])
                break

    two = cfg.get("jumlah_anggota", 3) == 2
    need_def = cfg["ambang"]["kelas_terdefinisi_min_2_anggota" if two else "kelas_terdefinisi_min"]
    if len(defined) >= need_def:
        ok(f"{len(defined)} kelas terdefinisi (≡ restriksi): {', '.join(sorted(defined))}")
    else:
        fail(
            f"baru {len(defined)} kelas terdefinisi, minimal {need_def}",
            "bentuk: A ≡ B ⊓ ∃r.C — harus menghasilkan klasifikasi terinferensi.",
        )

    card_preds = [
        OWL.minCardinality, OWL.maxCardinality, OWL.cardinality,
        OWL.minQualifiedCardinality, OWL.maxQualifiedCardinality, OWL.qualifiedCardinality,
    ]
    has_card = any(next(g.triples((r, p, None)), None) for r in restrictions for p in card_preds)
    has_data = any(next(g.triples((r, OWL.onDataRange, None)), None) for r in restrictions)
    if not has_data:
        for r in restrictions:
            for pred in (OWL.someValuesFrom, OWL.allValuesFrom, OWL.hasValue):
                for v in g.objects(r, pred):
                    if isinstance(v, URIRef) and str(v).startswith(str(XSD)):
                        has_data = True
                    elif isinstance(v, Literal):
                        has_data = True
    if has_card or has_data:
        ok(f"restriksi tipe data / kardinalitas ada (kardinalitas={has_card}, tipe data={has_data})")
    else:
        fail(
            "tidak ada restriksi tipe data atau kardinalitas",
            "contoh: ∃skor.xsd:integer[>= 90], atau ≥2 r.C",
        )

    trans = list(g.subjects(RDF.type, OWL.TransitiveProperty))
    inv = list(g.subjects(OWL.inverseOf, None))
    chain = list(g.subjects(OWL.propertyChainAxiom, None))
    props = (trans, inv, chain)
    if any(props):
        parts = []
        if trans:
            parts.append(f"transitif {len(trans)}")
        if inv:
            parts.append(f"invers {len(inv)}")
        if chain:
            parts.append(f"rantai {len(chain)}")
        ok("properti lanjutan: " + ", ".join(parts))
    else:
        fail(
            "tidak ada properti transitif, invers, maupun rantai properti",
            "contoh: Trans(bergantungPada), r ≡ s⁻, r ∘ s ⊑ t",
        )

    disj = list(g.subject_objects(OWL.disjointWith))
    all_disj = list(g.subjects(RDF.type, OWL.AllDisjointClasses))
    if disj or all_disj:
        ok(f"disjointness ada ({len(disj)} pasangan, {len(all_disj)} AllDisjointClasses)")
    else:
        fail("tidak ada disjointness", "minimal satu pasangan: A ⊓ B ⊑ ⊥")

    # ---- anotasi rdfs:comment ----
    head("6. Anotasi rdfs:comment")

    with_rule: list[str] = []
    without_comment: list[str] = []
    for c in classes:
        comments = [str(o) for o in g.objects(c, RDFS.comment)]
        if not comments:
            without_comment.append(str(c).split("#")[-1])
        elif any(re.search(r"\bR\d+\b", t) for t in comments):
            with_rule.append(str(c).split("#")[-1])

    if with_rule:
        ok(f"{len(with_rule)} kelas punya rdfs:comment berisi ID aturan")
    else:
        fail(
            "belum ada kelas dengan rdfs:comment berisi ID aturan",
            'anotasi rdfs:comment minimal berisi ID aturan, misalnya "R4".',
        )
    if without_comment:
        warn(
            f"{len(without_comment)} kelas belum punya rdfs:comment sama sekali: "
            f"{', '.join(sorted(without_comment)[:12])}"
            + (" ..." if len(without_comment) > 12 else "")
        )

    # ---- ABox ----
    head("7. Individu (ABox)")
    individuals = [s for s in g.subjects(RDF.type, OWL.NamedIndividual) if isinstance(s, URIRef)]
    if individuals:
        ok(f"{len(individuals)} individu")
    else:
        fail(
            "belum ada individu ber-tipe owl:NamedIndividual",
            "ABox harus cukup untuk menjawab seluruh competency question.",
        )
        fail(
            "syarat 'minimal 3 individu terklasifikasi lewat inferensi' belum bisa dicek",
            "pastikan individu tidak diberi rdf:type ke kelas hasil secara manual.",
        )


# --------------------------------------------------------------------------
# laporan & deliverable
# --------------------------------------------------------------------------

def check_aksioma(cfg: dict) -> None:
    head("8. Aksioma inti")

    tex = ROOT / "laporan" / "laporan.tex"
    if not tex.exists():
        warn("laporan/laporan.tex tidak ada, aksioma inti tidak bisa dicek")
        return

    body = tex.read_text(encoding="utf-8")
    ids: list[str] = []
    tanpa_rule: list[str] = []
    for line in body.splitlines():
        s = line.strip()
        if s.startswith("%"):
            continue
        m = re.match(r"(A\d+)\s*&", s)
        if not m:
            continue
        ids.append(m.group(1))
        if not re.search(r"\bR\d+\b", s):
            tanpa_rule.append(m.group(1))

    n = len(set(ids))
    need = cfg["ambang"]["aksioma_inti_min"]
    if n >= need:
        ok(f"{n} aksioma inti (minimal {need})")
    elif n == 0:
        fail(
            f"belum ada aksioma inti, minimal {need}",
            "satu baris per aksioma: ID & aksioma DL & aturan & alasan konstruksi",
        )
    else:
        fail(f"baru {n} aksioma inti, minimal {need}")

    if tanpa_rule:
        fail(
            f"aksioma tanpa ID aturan: {', '.join(tanpa_rule)}",
            "setiap aksioma wajib menyebut ID aturan yang diwakilinya",
        )


def check_report(cfg: dict) -> None:
    head("9. Laporan")

    if not LAPORAN_PDF.exists():
        warn("laporan/laporan.pdf belum ada (make report)")
        return

    pages = None
    try:
        import pypdf

        pages = len(pypdf.PdfReader(str(LAPORAN_PDF)).pages)
    except Exception:  # noqa: BLE001
        pass

    if pages is None:
        ok("laporan.pdf ada (jumlah halaman tidak terbaca, cek manual)")
    elif pages <= 10:
        ok(f"laporan.pdf {pages} halaman (maksimal 10 di luar lampiran)")
    else:
        warn(
            f"laporan.pdf {pages} halaman — batas 10 di luar lampiran. "
            "Pastikan lampiran dipisah dan tidak ikut dihitung."
        )

    check_aksioma(cfg)

    tex = (ROOT / "laporan" / "laporan.tex")
    if tex.exists():
        body = tex.read_text(encoding="utf-8")
        todo = len(re.findall(r"\\todo\{", body))
        if todo:
            warn(f"{todo} penanda \\todo{{}} masih tersisa di laporan.tex")
        else:
            ok("tidak ada \\todo{} tersisa di laporan.tex")

        # bagian wajib. Judul di tex bisa mengandung makro (\emph{Competency Question}),
        # jadi perintah LaTeX dibuang dulu sebelum dicocokkan.
        teks = re.sub(r"\\[a-zA-Z]+\{?", "", body)
        wajib = {
            "deskripsi domain": r"Deskripsi Domain",
            "aksioma inti": r"Aksioma Inti",
            "fitur wajib": r"Pemenuhan Fitur Wajib",
            "jawaban CQ": r"Jawaban Competency Question",
            "studi kasus inkonsistensi": r"Studi Kasus Inkonsistensi",
            "keputusan pemodelan": r"Keputusan Pemodelan",
            "aturan non-OWL": r"Aturan Non-OWL",
            "pembagian tugas": r"Pembagian Tanggung Jawab",
            "log AI": r"Log Penggunaan AI",
            "referensi": r"Referensi",
            "lampiran": r"Lampiran",
        }
        missing = [k for k, pat in wajib.items() if not re.search(pat, teks, re.I)]
        if missing:
            fail(f"bagian wajib belum ada di laporan.tex: {', '.join(missing)}")
        else:
            ok("11 bagian wajib ada di laporan.tex")


def main() -> int:
    cfg = yaml.safe_load((ROOT / "config.yaml").read_text(encoding="utf-8"))

    print("\033[1mIF4070 M1P1 — validator\033[0m")
    print(f"grup={cfg.get('grup')} anggota={cfg.get('jumlah_anggota')} domain={cfg.get('domain')}")

    rule_rows, cq_rows = check_rules(cfg)
    if cq_rows or rule_rows:
        check_cq(cq_rows, rule_rows, cfg)
    check_ontology(cfg)
    check_report(cfg)

    head("Ringkasan")
    fails = [m for lvl, m in RULES if lvl == "FAIL"]
    if fails:
        print(f"  \033[31m{len(fails)} FAIL\033[0m, {len(WARNS)} WARN")
        for m in fails:
            print(f"   - {m}")
        return 1
    print(f"  \033[32msemua syarat yang bisa dicek mesin terpenuhi\033[0m ({len(WARNS)} WARN)")
    if WARNS:
        for m in WARNS:
            print(f"   - {m}")
    print(
        "\n  Yang tetap harus dinilai manusia: mutu penalaran, ketepatan aksioma,\n"
        "  alasan pemilihan konstruksi, dan apakah minimal 3 individu benar-benar\n"
        "  terklasifikasi lewat reasoner."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
