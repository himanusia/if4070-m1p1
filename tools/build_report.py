#!/usr/bin/env python3
"""Bangun laporan PDF dari laporan/laporan.tex.

Tiga pekerjaan:
  1. Sunting \grup supaya cocok dengan config.yaml.
  2. Hasilkan lampiran daftar aturan dari aturan/daftar-aturan.md,
     supaya lampiran tidak pernah basi terhadap versi yang dibekukan.
  3. Terjemahkan notasi DL unicode (⊑ ∃ ⊓ ≡ ...) ke perintah LaTeX,
     lalu compile dan laporkan jumlah halaman.

Isi laporan tidak disentuh. Yang disunting cuma nama kelompok dan tabel lampiran.
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate import cell, col, parse_tables  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
LAP = ROOT / "laporan"
SRC = LAP / "laporan.tex"
BUILD = LAP / "_build.tex"
GEN = LAP / "generated" / "daftar-aturan.tex"

# notasi DL -> perintah LaTeX. \ensuremath supaya berlaku di mode teks maupun math.
UNICODE = {
    "⊑": r"\ensuremath{\sqsubseteq}",
    "⊒": r"\ensuremath{\sqsupseteq}",
    "≡": r"\ensuremath{\equiv}",
    "∃": r"\ensuremath{\exists}",
    "∀": r"\ensuremath{\forall}",
    "⊓": r"\ensuremath{\sqcap}",
    "⊔": r"\ensuremath{\sqcup}",
    "¬": r"\ensuremath{\neg}",
    "⊤": r"\ensuremath{\top}",
    "⊥": r"\ensuremath{\bot}",
    "≥": r"\ensuremath{\geq}",
    "≤": r"\ensuremath{\leq}",
    "∘": r"\ensuremath{\circ}",
    "⊆": r"\ensuremath{\subseteq}",
    "⊇": r"\ensuremath{\supseteq}",
    "⊂": r"\ensuremath{\subset}",
    "⊃": r"\ensuremath{\supset}",
    "∈": r"\ensuremath{\in}",
    "∉": r"\ensuremath{\notin}",
    "∪": r"\ensuremath{\cup}",
    "∩": r"\ensuremath{\cap}",
    "→": r"\ensuremath{\rightarrow}",
    "←": r"\ensuremath{\leftarrow}",
    "↦": r"\ensuremath{\mapsto}",
    "⊨": r"\ensuremath{\models}",
    "∅": r"\ensuremath{\varnothing}",
    "⁻": r"\ensuremath{^{-}}",
    "×": r"\ensuremath{\times}",
    "∞": r"\ensuremath{\infty}",
    "Δ": r"\ensuremath{\Delta}",
}

TEX_SPECIAL = {
    "\\": r"\textbackslash{}",
    "&": r"\&",
    "%": r"\%",
    "$": r"\$",
    "#": r"\#",
    "_": r"\_",
    "{": r"\{",
    "}": r"\}",
    "~": r"\textasciitilde{}",
    "^": r"\textasciicircum{}",
}


def tex_escape(s: str) -> str:
    out = "".join(TEX_SPECIAL.get(ch, ch) for ch in s)
    for uni, cmd in UNICODE.items():
        out = out.replace(uni, cmd)
    return out


def escape_unicode_only(s: str) -> str:
    for uni, cmd in UNICODE.items():
        s = s.replace(uni, cmd)
    return s


def generate_appendix() -> tuple[int, int]:
    md = ROOT / "aturan" / "daftar-aturan.md"
    tables = parse_tables(md.read_text(encoding="utf-8"))

    rule_rows: list[list[str]] = []
    cq_rows: list[list[str]] = []
    for header, rows in tables:
        if col(header, "pertanyaan") is not None:
            cq_rows = rows
        elif col(header, "sumber") is not None:
            rule_rows = rows

    def fill(rows: list[list[str]]) -> list[list[str]]:
        return [r for r in rows if any(c.strip() for c in r[1:])]

    out = ["% dihasilkan otomatis oleh tools/build_report.py — jangan disunting", ""]

    out.append(r"\begin{longtable}{@{}p{1.0cm} p{8.4cm} p{1.5cm} p{3.3cm}@{}}")
    out.append(r"\toprule")
    out.append(r"\textbf{ID} & \textbf{Aturan} & \textbf{Sumber} & \textbf{Catatan} \\")
    out.append(r"\midrule")
    out.append(r"\endfirsthead")
    out.append(r"\toprule")
    out.append(r"\textbf{ID} & \textbf{Aturan} & \textbf{Sumber} & \textbf{Catatan} \\")
    out.append(r"\midrule")
    out.append(r"\endhead")
    for r in fill(rule_rows):
        cells = [tex_escape(c.strip()) for c in (r + [""] * 4)[:4]]
        out.append(" & ".join(cells) + r" \\")
    out.append(r"\bottomrule")
    out.append(r"\end{longtable}")

    if fill(cq_rows):
        out.append("")
        out.append(r"\subsection*{Competency Question}")
        out.append(r"\begin{longtable}{@{}p{1.2cm} p{6.6cm} p{3.2cm} p{2.6cm}@{}}")
        out.append(r"\toprule")
        out.append(r"\textbf{ID} & \textbf{Pertanyaan} & \textbf{Jawaban} & \textbf{Aturan} \\")
        out.append(r"\midrule")
        out.append(r"\endfirsthead")
        out.append(r"\toprule")
        out.append(r"\textbf{ID} & \textbf{Pertanyaan} & \textbf{Jawaban} & \textbf{Aturan} \\")
        out.append(r"\midrule")
        out.append(r"\endhead")
        for r in fill(cq_rows):
            cells = [tex_escape(c.strip()) for c in (r + [""] * 4)[:4]]
            out.append(" & ".join(cells) + r" \\")
        out.append(r"\bottomrule")
        out.append(r"\end{longtable}")

    GEN.parent.mkdir(parents=True, exist_ok=True)
    GEN.write_text("\n".join(out) + "\n", encoding="utf-8")
    return len(fill(rule_rows)), len(fill(cq_rows))


def main() -> int:
    cfg = yaml.safe_load((ROOT / "config.yaml").read_text(encoding="utf-8"))
    grup = str(cfg.get("grup", "KXX"))

    if not SRC.exists():
        print(f"FAIL {SRC} tidak ada")
        return 1

    n_rules, n_cq = generate_appendix()
    print(f"lampiran  : {n_rules} aturan, {n_cq} CQ dari aturan/daftar-aturan.md")

    body = SRC.read_text(encoding="utf-8")
    body = body.replace(r"\newcommand{\grup}{KXX}", rf"\newcommand{{\grup}}{{{grup}}}")
    body = escape_unicode_only(body)
    BUILD.write_text(body, encoding="utf-8")
    print(f"grup      : {grup}")

    if not shutil.which("pdflatex"):
        print("FAIL pdflatex tidak ada di PATH")
        return 1

    for run in (1, 2):
        proc = subprocess.run(
            [
                "pdflatex", "-interaction=nonstopmode", "-halt-on-error",
                "-file-line-error", BUILD.name,
            ],
            cwd=LAP,
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            log = LAP / "_build.log"
            print(f"FAIL pdflatex gagal pada pass {run}")
            if log.exists():
                lines = log.read_text(errors="replace").splitlines()
                errs = [i for i, l in enumerate(lines) if l.startswith("!") or ".tex:" in l]
                for i in (errs[:6] or range(max(0, len(lines) - 25), len(lines))):
                    print(f"     {lines[i]}")
            print(f"     log lengkap: {log}")
            return 1

    pdf = LAP / "_build.pdf"
    if not pdf.exists():
        print("FAIL PDF tidak terbentuk")
        return 1
    final = LAP / "laporan.pdf"
    shutil.copy(pdf, final)

    pages = None
    try:
        import pypdf

        pages = len(pypdf.PdfReader(str(final)).pages)
    except Exception:  # noqa: BLE001
        pass

    app_page = None
    aux = LAP / "_build.aux"
    if aux.exists():
        m = re.search(r"\\newlabel\{sec:lampiran\}\{\{[^}]*\}\{(\d+)\}", aux.read_text(errors="replace"))
        if m:
            app_page = int(m.group(1))

    if pages is not None:
        body_pages = (app_page - 1) if app_page else pages
        print(f"halaman   : {pages} total, {body_pages} sebelum lampiran")
        if body_pages > 10:
            print("     WARN lewat 10 halaman di luar lampiran. Pangkas.")
        else:
            print("     OK   dalam batas 10 halaman di luar lampiran")

    print(f"selesai   : {final.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
