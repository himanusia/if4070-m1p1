# Folder Sumber

Dokumen sumber pengetahuan. Isinya **berkas**, bukan tautan — halaman web bisa berubah, dan
folder ini jadi korpus RAG di Milestone 2.

## Aturan penamaan

Nama berkas **diawali kode sumber** yang dipakai di kolom `Sumber` tabel aturan:

```
sumber/
  S1_buku_panduan.pdf
  S2_halaman_wiki_sistem_medali.pdf
  S3_house_rules_kelompok.pdf
```

- `S1` di tabel aturan → berkas yang namanya diawali `S1` (boleh `S1_...`).
- Kode tanpa berkas = FAIL di `make check`.
- House rules atau aturan fiktif yang kelompok buat sendiri **tetap** jadi dokumen tersendiri
  di sini (misalnya `S3_house_rules_kelompok.pdf`), supaya bisa diambil RAG di Milestone 2.

## Cara menyimpan halaman web

Jangan simpan URL. Simpan isinya:

- Print to PDF dari browser (Chrome: `Cmd+P` → Save as PDF), atau
- `curl -sL "<url>" | pandoc -f html -t pdf -o S2_halaman.pdf` kalau isinya server-rendered.

Sertakan tanggal akses di dalam berkas atau di nama (mis. `S2_wiki_20261027.pdf`) kalau
halamannya dinamis.

## Batas ukuran

ZIP pengumpulan maksimal 25 MB. Kalau dokumen sumber kegedean, taruh di Google Drive dengan
akses untuk asisten, lalu cantumkan tautannya di laporan — bukan di folder ini.
