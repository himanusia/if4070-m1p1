# Batas penggunaan AI

Sumber: `docs/spesifikasi-m1p1.pdf` halaman 5.

| Boleh, dengan deklarasi | Tidak boleh |
|---|---|
| Memahami konsep atau materi kuliah | Membuat daftar aturan atau competency question |
| Menerjemahkan atau menyederhanakan dokumen sumber | Membuat ontologi, baik TBox maupun ABox |
| Eksplorasi awal domain | Menulis notasi logika deskripsi |
| Memahami pesan galat Protégé | Menulis analisis, keputusan pemodelan, dan pembahasan di laporan |

Konsekuensi pelanggaran: bagian terkait **tidak dinilai**. Penggunaan yang tidak
dideklarasikan: bagian terkait **bernilai nol**.

## Pemetaan ke berkas repo ini

| Berkas | Status AI |
|---|---|
| `aturan/daftar-aturan.md` | ditulis tangan |
| `ontologi/*.owl` (TBox & ABox) | ditulis tangan di Protégé |
| `laporan/laporan.tex` — aksioma, analisis, keputusan pemodelan, pembahasan | ditulis tangan |
| `sumber/` — ekstraksi & penyederhanaan dokumen | boleh, dengan deklarasi |
| `tools/`, `Makefile`, struktur repo | infrastruktur, di luar kategori yang dinilai |
| penjelasan galat Protégé | boleh, dengan deklarasi |

Log penggunaan AI wajib diisi di `laporan/laporan.tex` bagian *Log Penggunaan AI*,
walaupun yang dipakai cuma kategori kolom kiri.
