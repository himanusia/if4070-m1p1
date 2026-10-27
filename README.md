# IF4070 — Milestone 1 Part 1

Daftar aturan, *competency question*, dan ontologi OWL untuk Tugas Besar IF4070
Representasi Pengetahuan dan Penalaran.

**Deadline: Kamis, 29 Oktober 2026, 17.59 WIB.** Terlambat = tidak diterima.

---

## Batas AI

Spek halaman 5 membagi penggunaan AI jadi dua kolom. Repo ini dibangun supaya pembagian itu
kelihatan secara mekanis: yang boleh dikerjakan kakas, dan yang harus tangan manusia.

| Boleh, dengan deklarasi | Tidak boleh |
|---|---|
| Memahami konsep atau materi kuliah | **Membuat daftar aturan atau competency question** |
| Menerjemahkan atau menyederhanakan dokumen sumber | **Membuat ontologi, baik TBox maupun ABox** |
| Eksplorasi awal domain | **Menulis notasi logika deskripsi** |
| Memahami pesan galat Protégé | **Menulis analisis, keputusan pemodelan, dan pembahasan di laporan** |

Konsekuensinya konkret:

- `aturan/daftar-aturan.md` — **diisi tangan.** AI tidak menulis R1..Rn maupun CQ1..CQn.
- `ontologi/*.owl` — **dibangun di Protégé, diisi tangan.** Repo cuma menyediakan header kosong
  dengan prefix & IRI yang benar, plus kanal validasi.
- `laporan/laporan.tex` — **kerangka bagian saja.** Semua aksioma, analisis, keputusan pemodelan,
  dan pembahasan ditulis tangan.
- Yang boleh otomatis: struktur repo, checker, packaging, build PDF, penjelasan galat Protégé,
  dan ekstraksi/penyederhanaan dokumen sumber ke `sumber/`.

Isi log AI di `laporan/laporan.tex` bagian *Log Penggunaan AI* walaupun cuma dipakai buat hal
di kolom kiri. Penggunaan yang tidak dideklarasikan = bagian terkait bernilai nol.

---

## Struktur

```
config.yaml                     grup, jumlah anggota, ambang minimal, IRI ontologi
aturan/daftar-aturan.md         TABEL ATURAN + TABEL COMPETENCY QUESTION  (diisi tangan)
sumber/                         dokumen sumber, nama berkas diawali kode S1_, S2_, ...
ontologi/KXX_M1P1_ontologi.owl               ontologi utama (RDF/XML)     (dari Protege)
ontologi/KXX_M1P1_ontologi_inkonsisten.owl   salinan buat studi kasus     (dari Protege)
laporan/laporan.tex             kerangka laporan, build ke PDF
tools/validate.py               cek seluruh syarat spek yang bisa dicek mesin
tools/selftest.py               uji validator pakai domain dummy
tools/package.py                bikin KXX_M1P1.zip sesuai struktur deliverable
tools/build_report.py           laporan.tex -> PDF + hitung halaman + lampiran otomatis
tools/reason.sh                 jalankan HermiT lewat ROBOT, headless
docs/spesifikasi-m1p1.pdf       spek asli
docs/checklist.md               daftar centang spek -> lokasi -> dicek oleh apa
```

## Setup (sekali)

```bash
make setup     # venv + rdflib, pyyaml, pypdf
make doctor    # cek java, robot, protege, pdflatex
make selftest  # uji checker-nya sendiri (fixture lengkap harus 0 FAIL)
```

Sudah terpasang di mesin ini:

- Java 21 — `~/.hermes/tools/jdk/jdk-21.0.13+9/Contents/Home`
- ROBOT 1.9.11 (HermiT headless) — `~/.hermes/tools/robot.jar`
- Protégé 5.6.9 — `~/.hermes/tools/protege/Protege-5.6.9/Protégé.app` (bawa JRE sendiri)
- pdfTeX (TeX Live 2026)

`make selftest` penting: dia membangun domain dummy yang memenuhi semua syarat,
lalu memastikan validator tidak salah lapor. Kalau lu mengubah validator, jalankan ini.

## Siklus kerja

```bash
make check      # validator: aturan, CQ, ontologi, sumber, fitur wajib
make reason     # HermiT lewat ROBOT pada ontologi utama, harus konsisten
make reason-bad # HermiT pada salinan inkonsisten, harus TIDAK konsisten
make report     # laporan.tex -> laporan.pdf, sekalian hitung halaman
make package    # K11_M1P1.zip
make open       # buka ontologi di Protege
```

`make reason` tidak butuh buka Protégé — ROBOT memanggil HermiT yang sama secara
headless, jadi lu bisa cek konsistensi tiap kali selesai menyunting.

Urutannya: `check` sampai bersih → `reason` → `report` → `package`. `package.py` menolak
membuat zip kalau `make check` masih gagal, supaya tidak ada pengumpulan setengah jadi.

## Rencana 3 hari

Deadline Kamis 17.59, hari ini Selasa.

**Selasa** — domain, `sumber/`, tabel aturan.

Domain sudah dipilih: **mahjong 4 pemain**, varian klub Indonesia dengan house
rules. Paragraf perbedaan struktural dari domain terdekat yang dilarang wajib ada
di laporan — lihat `docs/checklist.md`.

1. Kumpulkan dokumen sumber **sebagai berkas**, bukan tautan. Simpan di `sumber/` dengan
   nama `S1_...`, `S2_...`. Simpan PDF halaman web, jangan URL-nya.
3. Tulis R1..R12+ di tabel aturan. Tandai `non-OWL` minimal 2, `twist` untuk house rules.
4. `make check` — bagian aturan harus hijau dulu sebelum lanjut.

**Rabu** — ontologi.

5. Buka `ontologi/KXX_M1P1_ontologi.owl` di Protégé, simpan ulang, baru tambah kelas.
   Target 30–60 kelas, jangan lebih.
6. Bangun TBox: kelas terdefinisi (≡), restriksi, disjointness, properti transitif/invers/rantai.
7. ABox: individu cukup buat menjawab semua CQ. Pastikan minimal 3 individu terklasifikasi
   **oleh reasoner**, bukan asersi manual — cara ceknya: individu itu tidak punya `rdf:type`
   eksplisit ke kelas hasil, tapi masuk setelah reasoner jalan.
8. `make reason` lalu `make check`.
9. Salin ontologi ke `..._inkonsisten.owl`, suntik satu kontradiksi, jalankan reasoner,
   **screenshot penjelasan Protégé**. Ini bukti yang diminta spek, tidak bisa diganti teks.

**Kamis pagi** — laporan.

10. Isi `laporan.tex`: aksioma inti (≥10, notasi DL + ID aturan + alasan konstruksi),
    tabel fitur wajib, DL Query + hasil per CQ, studi kasus inkonsistensi, keputusan pemodelan
    (≥3), aturan non-OWL + alasan teknis, pembagian tugas, log AI, referensi, lampiran.
11. `make report` — pastikan ≤10 halaman di luar lampiran.
12. `make package` → `KXX_M1P1.zip` ≤25 MB. Yang mengumpulkan: **NIM terkecil**.

## Setelah dikumpulkan

Daftar aturan **dibekukan**. Dipakai lagi di Part 2 (diterjemahkan ke Prolog) dan Milestone 2
(jadi korpus RAG). Perubahan setelah itu butuh izin asisten lewat email/chat + dicatat di
laporan Part 2. Karena itu jangan buru-buru mengunci domain yang tidak bisa dipertanggungjawabkan
strukturnya.
