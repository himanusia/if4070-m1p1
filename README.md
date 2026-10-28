# IF4070 M1P1 — Kelompok K11

Tooling untuk Tugas Besar IF4070 Milestone 1 Part 1. Domain: mahjong riichi (WRC Rules 2025) + house rules klub.

## Prasyarat

| Kebutuhan | Dicari dari mana |
|---|---|
| Java ≥ 11 | `JAVA_HOME`, lalu `/usr/libexec/java_home`, lalu `~/.hermes/tools/jdk/*/Contents/Home`, lalu `PATH` |
| ROBOT (HermiT headless) | `ROBOT`, lalu `~/.hermes/tools/robot.jar` / `~/.hermes/tools/*/robot.jar` |
| Protégé | `PROTEGE`, lalu `/Applications`, lalu `~/.hermes/tools/*/*/Protégé.app` |
| pdfTeX | `PATH` |
| Python ≥ 3.9 + `requirements.txt` | venv lokal `.venv/` |

Tidak ada path yang di-hardcode. Kalau penemuan otomatis gagal, override:

```bash
make doctor JAVA_HOME=/path/to/jdk ROBOT=/path/robot.jar PROTEGE="/Applications/Protégé.app"
```

```bash
make setup     # bikin .venv + install requirements.txt
make doctor    # tampilkan path yang benar-benar dipakai
```

## Perintah

| Perintah | Fungsi |
|---|---|
| `make check` | Cek kelengkapan: jumlah & penomoran aturan, CQ, berkas sumber, jumlah kelas, fitur DL, anotasi, bagian laporan. Exit 1 kalau ada FAIL. |
| `make selftest` | Uji validator pakai domain dummy. Harus 0 FAIL. |
| `make reason` | HermiT pada ontologi utama lewat ROBOT. Harus konsisten. |
| `make reason-bad` | HermiT pada salinan inkonsisten. Harus **tidak** konsisten. |
| `make report` | `laporan.tex` → `laporan.pdf`, hitung halaman, lampiran dari tabel aturan. |
| `make package` | Susun `K11_M1P1.zip`. Menolak kalau `make check` gagal. |
| `make open` | Buka ontologi utama di Protégé. |
| `make review` | Gerbang sebelum submit: `check` → `reason` → `reason-bad` → `report` → `package`, berhenti di langkah pertama yang gagal. |
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
config.yaml                                 grup, anggota, domain, ambang, IRI
aturan/daftar-aturan.md                     tabel aturan + tabel competency question
sumber/                                     dokumen sumber, nama diawali S1_, S2_, ...
ontologi/K11_M1P1_ontologi.owl              ontologi utama (RDF/XML)
ontologi/K11_M1P1_ontologi_inkonsisten.owl  salinan untuk studi kasus
laporan/laporan.tex                         laporan, build ke PDF
laporan/gambar/                             screenshot penjelasan Protégé
tools/validate.py                           validator
tools/selftest.py                           uji validator
tools/reason.sh                             HermiT lewat ROBOT
tools/build_report.py                       build PDF + lampiran otomatis
tools/package.py                            packaging zip
```

## Konvensi

- Berkas di `sumber/` diawali kode yang dipakai di kolom Sumber (`S1_...`).
- Satu baris = satu aturan. ID `R1..Rn` berurutan tanpa lompatan.
- Kolom Catatan: `non-OWL` untuk aturan yang tidak bisa di OWL, `twist` untuk house rules.
- Nama berkas deliverable diturunkan dari `config.yaml`.
- `laporan.tex` boleh diketik dengan notasi DL unicode (`⊑ ∃ ⊓ ≡`); `build_report.py` yang menerjemahkannya.
