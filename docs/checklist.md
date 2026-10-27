# Checklist spek → lokasi → dicek oleh apa

Semua baris di bawah berasal dari `docs/spesifikasi-m1p1.pdf`. Kolom terakhir
menunjukkan apa yang memverifikasi: `make check` (otomatis), `make reason`
(HermiT), atau manual (tidak bisa dinilai mesin, harus tangan).

## Daftar aturan

| # | Syarat | Lokasi | Dicek oleh |
|---|---|---|---|
| 1 | Tabel aturan punya kolom ID, aturan, sumber, catatan | `aturan/daftar-aturan.md` | check |
| 2 | ID berurutan R1, R2, ... | idem | check |
| 3 | Satu aturan = satu pernyataan teruji | idem | manual (check hanya menandai kalimat majemuk) |
| 4 | Minimal 12 aturan (3 orang) / 9 (2 orang) | idem | check |
| 5 | Minimal 2 aturan bertanda `non-OWL` | idem | check |
| 6 | House rules / aturan fiktif bertanda `twist` | idem | check (WARN kalau kosong) |
| 7 | Setiap kode sumber punya berkas di `sumber/` | `sumber/S1_...`, dst | check |
| 8 | Minimal 8 competency question | `aturan/daftar-aturan.md` | check |
| 9 | Setiap aturan non-OWL diuji minimal 1 CQ | idem | check |
| 10 | Minimal 1 CQ butuh rantai ≥3 aturan | idem | check |
| 11 | Minimal 2 CQ berjawaban "Tidak" | idem | check |

## Ontologi

| # | Syarat | Lokasi | Dicek oleh |
|---|---|---|---|
| 12 | RDF/XML, konsisten di HermiT | `ontologi/K11_M1P1_ontologi.owl` | check + reason |
| 13 | rdfs:comment berisi ID aturan pada kelas/properti | idem | check |
| 14 | 30–60 kelas | idem | check |
| 15 | ABox cukup untuk semua CQ | idem | manual + reason |
| 16 | Minimal 3 individu terklasifikasi **lewat inferensi** | idem | manual + reason |
| 17 | Minimal 10 aksioma inti dalam notasi DL + ID aturan + alasan konstruksi | `laporan/laporan.tex` | manual |
| 18 | Kelas terdefinisi (≡) min. 3 (3 orang) / 2 (2 orang), dipakai CQ | owl + laporan | check + manual |
| 19 | Restriksi tipe data / kardinalitas, dipakai CQ | idem | check + manual |
| 20 | Properti transitif / invers / rantai, dipakai CQ | idem | check + manual |
| 21 | Disjointness, dipakai CQ | idem | check + manual |
| 22 | Salinan inkonsisten + penjelasan Protégé (screenshot) | `ontologi/..._inkonsisten.owl` + `laporan/gambar/` | reason + manual |
| 23 | Aturan non-OWL + alasan teknis | `laporan/laporan.tex` | manual |

## Deliverable

| # | Syarat | Lokasi | Dicek oleh |
|---|---|---|---|
| 24 | `K11_M1P1.zip` berisi 4 komponen | hasil `make package` | package |
| 25 | Laporan ≤10 halaman di luar lampiran | `laporan/laporan.pdf` | report + check |
| 26 | Bagian laporan lengkap (11 bagian) | `laporan/laporan.tex` | check |
| 27 | ZIP ≤25 MB | — | package |
| 28 | Dikumpulkan oleh NIM terkecil | 13521003 | manual |

---

## Yang paling gampang bikin kehilangan nilai

1. **Domain terdekat yang dilarang.** Mahjong tidak punya kembaran langsung di
   daftar larangan. Tetangga terdekatnya **Clash Royale** (permainan kartu) dan
   **Settlers of Catan** (permainan meja). Paragraf perbedaan struktural wajib
   ada dan harus menunjuk struktur, bukan tema: mahjong adalah permainan
   *set-collection / tile-shedding*, empat pemain **independen** (tidak ada
   kemitraan), memakai 136 tile dari 34 jenis dengan tepat 4 salinan per jenis,
   dan alurnya giliran → ambil → buang → bentuk meld → *agari*. Tidak ada
   ekonomi sumber daya, tidak ada deck-building, tidak ada kemitraan.
2. **Mahjong itu sangat populer di internet — ini risiko terbesar lu.** Wiki
   riichi, daftar yaku, dan budaya anime bikin model bahasa hafal garis besarnya,
   persis yang dikritik kriteria 3 spek. Mitigasinya dua: (a) jangan pilih riichi
   sebagai varian utama, (b) pakai varian klub Indonesia + `house rules`, dan
   sebut variannya eksplisit di laporan dan di `sumber/`.
3. **Jebakan skor mahjong.** Han, fu, dan pembayaran itu aritmetika murni. Kalau
   semua aturan jadi `non-OWL`, kedalaman penalaran hilang dan justru itu yang
   dinilai. Jaga aturan non-OWL di kisaran 2–4 saja; yang struktural (bentuk
   tangan, status terbuka/tertutup, tenpai, furiten) taruh di OWL.
4. **`non-OWL` harus jujur.** Tandai aturan non-OWL karena memang tidak bisa
   (agregasi skor, pengecualian, asumsi dunia tertutup), bukan karena malas
   memodelkan. Alasan teknisnya dinilai di laporan.
5. **Individu terklasifikasi inferensi, bukan asersi.** Kalau individu diberi
   `rdf:type` langsung ke kelas hasil, syarat nomor 16 tidak terpenuhi walaupun
   ontologinya konsisten.
6. **Screenshot inkonsistensi.** Tanpa gambar jendela *Explain inconsistency*,
   bagian studi kasus tidak dinilai penuh. Tidak bisa diganti teks.

---

## Bahan DL yang natural di mahjong

Ini bukan aturan siap pakai — ini peta konsep mana yang secara alami cocok
dengan konstruksi DL mana, supaya lu nggak memaksakan konstruksi ke aturan yang
salah bentuk. Aturannya sendiri tetap lu tulis.

| Konstruksi DL | Konsep mahjong yang natural | Kenapa cocok |
|---|---|---|
| Kardinalitas `∃=n` | tangan 13 tile, tepat 4 pemain, 4 salinan per jenis, kan = 4 tile | mahjong memang mendefinisikan jumlah, jadi kardinalitasnya jujur |
| Kelas terdefinisi `≡` | tangan tertutup ≡ tangan ⊓ ¬∃meldTerbuka.Meld; tenpai ≡ tangan ⊓ ∃menunggu.Tile | status ini benar-benar hasil inferensi, bukan label |
| Disjointness `⊓ ⊑ ⊥` | jenis tile (man/pin/sou/honor), terbuka ⊓ tertutup | saling lepas secara definisi, bukan pilihan model |
| Properti transitif | urutan angin (timur → selatan → barat → utara) | relasi urutan, transitif secara alami |
| Properti invers | `membuang` / `dibuangOleh`, `memanggil` / `dipanggil` | pasangan relasi yang memang dua arah |
| Rantai properti `r ∘ s ⊑ t` | pemain ∘ dudukDi ⊑ bermainDi meja | komposisi peran jadi peran |
| Pengecualian (non-OWL) | furiten: tile yang sudah dibuang sendiri tidak boleh menang | butuh tahu seluruh riwayat buang = dunia tertutup |
| Agregasi (non-OWL) | nilai han, fu, dan pembayaran akhir | OWL tidak punya operator aritmetika |
