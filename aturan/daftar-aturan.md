# Daftar Aturan — Milestone 1 Part 1

> **Berkas ini diisi tangan.** Spek halaman 5: membuat daftar aturan dan competency question
> tidak boleh pakai AI generatif. Yang boleh: memahami konsep, menerjemahkan/menyederhanakan
> dokumen sumber, dan eksplorasi awal domain — semuanya dengan deklarasi di log AI.
>
> Setelah dikumpulkan, tabel ini **dibekukan**. Dipakai di Part 2 (Prolog) dan Milestone 2 (korpus RAG).

## 1. Tabel Aturan

Aturan penulisan:

- Satu baris = satu aturan = satu pernyataan yang bisa diuji benar/salah. Kalau butuh "dan",
  pecah jadi dua baris.
- Kolom `Sumber` berisi kode `S1`, `S2`, ... dan setiap kode **wajib** punya berkas di
  `sumber/` yang namanya diawali kode itu (`S1_buku_panduan.pdf`).
- Kolom `Catatan`: tulis `non-OWL` untuk aturan yang tidak bisa direpresentasikan di OWL,
  `twist` untuk house rules / aturan fiktif. Boleh keduanya: `non-OWL, twist`.

| ID | Aturan | Sumber | Catatan |
|---|---|---|---|
| R1 |  |  |  |
| R2 |  |  |  |
| R3 |  |  |  |
| R4 |  |  |  |
| R5 |  |  |  |
| R6 |  |  |  |
| R7 |  |  |  |
| R8 |  |  |  |
| R9 |  |  |  |
| R10 |  |  |  |
| R11 |  |  |  |
| R12 |  |  |  |

Minimal 12 aturan (kelompok 3 orang) atau 9 (2 orang). Minimal 2 bertanda `non-OWL`.
Tambah baris kalau perlu — ID harus tetap berurutan R1..Rn tanpa lompatan.

## 2. Tabel Competency Question

Aturan penulisan:

- Kolom `Aturan` menyebut **semua** aturan yang dipakai menjawab, misalnya `R3, R7, R8`.
- Minimal satu CQ harus menyebut **3 aturan atau lebih** (uji rantai penalaran).
- Minimal dua CQ berjawaban **"Tidak"** (bahan penjelasan "mengapa tidak" di Part 2).
- Setiap aturan `non-OWL` harus muncul di minimal satu CQ.
- Kolom `Jawaban` tulis jawaban akhirnya saja; jalur penalarannya masuk laporan.

| ID | Pertanyaan | Jawaban | Aturan |
|---|---|---|---|
| CQ1 |  |  |  |
| CQ2 |  |  |  |
| CQ3 |  |  |  |
| CQ4 |  |  |  |
| CQ5 |  |  |  |
| CQ6 |  |  |  |
| CQ7 |  |  |  |
| CQ8 |  |  |  |

Minimal 8 CQ.

## 3. Catatan keputusan (bahan laporan, bukan dinilai di tabel)

Simpan alasan kenapa aturan tertentu dianggap non-OWL di sini sambil jalan — ini yang nanti
jadi bagian *Aturan Non-OWL* dan *Keputusan Pemodelan* di laporan. Ditulis tangan.
