# IF4070 M1P1 — Kelompok K11

Artefak Tugas Besar IF4070 Representasi Pengetahuan dan Penalaran, Milestone 1 Part 1.
Domain: mahjong 4 pemain (varian klub, house rules).

Repo ini tooling dan kerangka berkas. Isi tugasnya ditulis tangan.

## Prasyarat

| Kebutuhan | Versi | Lokasi di mesin ini |
|---|---|---|
| Java | 21 | `~/.hermes/tools/jdk/jdk-21.0.13+9/Contents/Home` |
| ROBOT (HermiT headless) | 1.9.11 | `~/.hermes/tools/robot.jar` |
| Protégé | 5.6.9 | `~/.hermes/tools/protege/Protege-5.6.9/Protégé.app` |
| pdfTeX | TeX Live 2026 | `/Library/TeX/texbin` |
| Python | 3.13 | venv lokal di `.venv/` |

```bash
make setup     # bikin .venv + install requirements.txt
make doctor    # cek semua di atas ada
```

## Perintah

| Perintah | Fungsi |
|---|---|
| `make check` | Validasi syarat spek: jumlah & penomoran aturan, CQ, berkas sumber, jumlah kelas, fitur DL wajib, anotasi, bagian laporan. Exit 1 kalau ada FAIL. |
| `make selftest` | Uji validator pakai domain dummy. Harus 0 FAIL. |
| `make reason` | HermiT pada ontologi utama lewat ROBOT. Harus konsisten. |
| `make reason-bad` | HermiT pada salinan inkonsisten. Harus **tidak** konsisten. |
| `make report` | `laporan.tex` → `laporan.pdf`, hitung halaman, lampiran dari tabel aturan. |
| `make package` | Susun `K11_M1P1.zip`. Menolak kalau `make check` gagal. |
| `make open` | Buka ontologi utama di Protégé. |
| `make clean` | Hapus venv dan artefak build. |

## Alur pengerjaan

```bash
make setup

# 1. dokumen sumber -> sumber/S1_..., S2_...
# 2. tabel aturan & CQ -> aturan/daftar-aturan.md
make check

# 3. ontologi di Protégé
make open
make check && make reason

# 4. salin ontologi, suntik kontradiksi, screenshot penjelasan
make reason-bad

# 5. laporan
make report

# 6. kirim
make package
```

`make check` di awal pasti gagal — itu daftar kerja, bukan bug.

## Layout

```
config.yaml                                 grup, anggota, domain, ambang minimal, IRI
aturan/daftar-aturan.md                     tabel aturan + tabel competency question
sumber/                                     dokumen sumber, nama diawali S1_, S2_, ...
ontologi/K11_M1P1_ontologi.owl              ontologi utama (RDF/XML)
ontologi/K11_M1P1_ontologi_inkonsisten.owl  salinan untuk studi kasus
laporan/laporan.tex                         laporan, build ke PDF
laporan/gambar/                             screenshot penjelasan Protégé
tools/validate.py                           validator syarat spek
tools/selftest.py                           uji validator
tools/reason.sh                             HermiT lewat ROBOT
tools/build_report.py                       build PDF + lampiran otomatis
tools/package.py                            packaging zip
docs/                                       spek, checklist, catatan batas AI
```

## Konvensi

- Nama berkas di `sumber/` diawali kode yang dipakai di kolom Sumber (`S1_...`).
- Satu baris = satu aturan. ID `R1..Rn` berurutan, tanpa lompatan.
- Kolom Catatan: `non-OWL` untuk aturan yang tidak bisa di OWL, `twist` untuk house rules.
- Nama berkas deliverable diturunkan dari `config.yaml`. Ganti grup di situ, bukan di nama berkas.
- `laporan/laporan.tex` boleh diketik dengan notasi DL unicode (`⊑ ∃ ⊓ ≡`); `build_report.py` yang menerjemahkan ke LaTeX.

## Rujukan

- `docs/checklist.md` — syarat spek, dipetakan ke berkas dan ke cara verifikasinya
- `docs/batas-ai.md` — batas penggunaan AI
- `docs/spesifikasi-m1p1.pdf` — spek asli
