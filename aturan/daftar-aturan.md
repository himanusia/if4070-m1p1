# Daftar Aturan

## 1. Tabel Aturan

| ID | Aturan | Sumber | Catatan |
|---|---|---|---|
| R1 | Setiap tangan pemain terdiri atas 13 atau 14 tile, tidak termasuk tile tambahan dari quad | S1 §3.3 |  |
| R2 | Tile terminal adalah tile suit bernomor 1 atau 9 | S1 §3.1 |  |
| R3 | Tile inside adalah tile suit bernomor 2 sampai 8 | S1 §3.1 |  |
| R4 | Tile honour terdiri atas tile wind dan tile dragon, yang saling lepas dengan tile suit | S1 §3.1, §4.1 |  |
| R5 | Sequence adalah tiga tile berurutan pada satu suit, tidak melingkar dari 9 ke 1, tanpa tile honour | S1 §3.2 | non-OWL |
| R6 | Quad terdiri atas empat tile identik dan dihitung sebagai satu group | S1 §3.2 |  |
| R7 | Pair terdiri atas dua tile identik dan tidak tergolong group | S1 §3.2 |  |
| R8 | Tangan tergolong open jika memiliki minimal satu group melded di luar tile kemenangan; selain itu closed | S1 §3.3 |  |
| R9 | Tangan tergolong valid jika memiliki empat group dan satu pair, tujuh pair berbeda, atau Thirteen Orphans | S1 §3.3 |  |
| R10 | Tangan tergolong menang jika valid dan memiliki paling sedikit satu yaku | S1 §3.3 |  |
| R11 | Tangan tergolong tenpai jika hanya membutuhkan satu tile pelengkap dan tile itu masih mungkin ada (belum empat salinan dipegang tangan itu) | S1 §3.3 | non-OWL |
| R12 | Tan'yao: tangan yang seluruh tilenya inside mendapat 1 han, baik open maupun closed | S1 §11.5.1 |  |
| R13 | Yakuhai: setiap triplet atau quad dragon, seat wind pemain, atau round wind memberi 1 han | S1 §3.1, §11.5.1 |  |
| R14 | Dora bukan yaku | S1 §3.5 |  |
| R15 | Setiap dora di tangan pemenang menambah 1 han | S1 §11.4 |  |
| R16 | Total han adalah jumlah han seluruh yaku ditambah jumlah dora | S1 §3.5, §11.2 | non-OWL |
| R17 | Kategori menurut total han: 5 mangan, 6–7 haneman, 8–10 baiman, 11–12 sanbaiman, 13 ke atas yonbaiman | S1 §11.2 |  |
| R18 | Pemenang yang skor mejanya terendah sebelum tangan dimulai mendapat tambahan 1 han (Bonus Comeback), hanya jika tangannya sudah memiliki minimal satu yaku | S2 | non-OWL, twist |
| R19 | Tan'yao pada tangan open tidak bernilai han, menggantikan R12 untuk tangan open | S2 | non-OWL, twist |

Satu baris satu aturan. Kolom Sumber pakai kode `S1`, `S2`, ... dan berkasnya ada di `sumber/`.
Kolom Catatan: `non-OWL` untuk aturan yang tidak bisa di OWL, `twist` untuk house rules.

## 2. Tabel Competency Question

| ID | Pertanyaan | Jawaban | Aturan |
|---|---|---|---|
| CQ1 | Apakah tangan yang hanya berisi group concealed tergolong closed? | Ya. Tidak ada group melded | R8 |
| CQ2 | Apakah tile 1 bambu tergolong terminal sekaligus inside? | Tidak. Terminal dan inside saling lepas | R2, R3 |
| CQ3 | Apakah triplet dragon dapat dihitung sebagai sequence? | Tidak. Sequence tidak memuat honour | R4, R5 |
| CQ4 | Apakah 8-9-1 bambu adalah sequence yang sah? | Tidak. Sequence tidak melingkar dari 9 ke 1 | R5 |
| CQ5 | Apakah tangan dengan satu quad, tiga group lain, dan satu pair tetap valid jika pair ikut dihitung sebagai group? | Tidak. Pair bukan group, jadi hanya ada empat group tanpa pair | R6, R7, R9 |
| CQ6 | Apakah tangan empat group dan satu pair tanpa yaku tergolong menang? | Tidak. Tangan valid, tetapi tanpa yaku | R7, R9, R10 |
| CQ7 | Apakah tangan yang menunggu tile kelima dari jenis yang sudah ia pegang empat buah tergolong tenpai? | Tidak. Tile pelengkap itu tidak mungkin ada | R1, R11 |
| CQ8 | Tangan open berisi meld 567m dan sisa 234m 345p 678s 55s, tanpa yaku lain. Apakah tangan menang menurut WRC? | Ya. Valid dan seluruh tile inside, jadi Tan'yao 1 han | R3, R8, R9, R10, R12 |
| CQ9 | Apakah tangan valid tanpa yaku dengan 3 dora tergolong menang? | Tidak. Dora bukan yaku | R10, R14, R15 |
| CQ10 | Tangan open dengan triplet dragon putih sebagai satu-satunya yaku dan 4 dora. Termasuk kategori apa? | Mangan (1 + 4 = 5 han) | R13, R15, R16, R17 |
| CQ11 | Pemain dengan skor terendah menang dengan Tan'yao closed dan 3 dora. Berapa han dan apa kategorinya? | 5 han (1 + 3 + 1 Bonus Comeback), mangan. Tanpa bonus hanya 4 han | R12, R15, R16, R17, R18 |
| CQ12 | Menurut house rules, apakah tangan pada CQ8 tetap tangan menang? | Tidak. Tan'yao open tidak bernilai, sehingga tangan tanpa yaku | R8, R10, R12, R19 |

Notasi tile: m = karakter, p = lingkaran, s = bambu.
Kolom Aturan sebut semua aturan yang dipakai, misalnya `R3, R7, R8`.

## Sumber

| Kode | Berkas | Isi |
|---|---|---|
| S1 | `sumber/S1_WRC_Rules_2025.pdf` | World Riichi Championship Rules 2025 (v20250526), worldriichi.org |
| S2 | `sumber/S2_house_rules_kelompok.md` | House rules fiktif kelompok (Bonus Comeback, Tan'yao Tertutup) |
