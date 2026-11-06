# Milestone 1 Part 2 — K11 (Mahjong)

Translasi basis pengetahuan Part 1 (OWL/DL) ke SWI-Prolog, dengan meta-interpreter
yang membangun pohon bukti dari `aturan/3`.

## Menjalankan

Butuh SWI-Prolog 9 atau lebih baru.

```
swipl src/main.pl          # muat kb + abox, jalankan seluruh CQ
swipl test/run_tests.pl    # jalankan cq.json + tests.json
swipl src/kb.pl            # kb.pl harus load bersih tanpa triple individu
```

## Susunan berkas

| Berkas | Isi |
|---|---|
| `src/kb.pl` | meta-interpreter, antarmuka (`classify/2`, `explain/2`, `why_not/2`), 19 aturan domain sebagai `aturan/3`. Tanpa triple individu. |
| `src/abox.pl` | seluruh individu sebagai `triple/3` |
| `src/main.pl` | titik masuk: muat kb + abox, jalankan CQ |
| `test/cq.json` | 12 CQ beserta kasusnya |
| `test/tests.json` | 16 kasus uji, 6 kategori |
| `test/run_tests.pl` | runner yang mencocokkan hasil dengan `harapan` |

## Antarmuka

```prolog
?- explain(classify(tangan_cq8, winning_hand), Bukti).
?- why_not(classify(tangan_tanpa_yaku, winning_hand), Alasan).
?- classify(tangan_cq8, winning_hand).
```

Bentuk bukti:

```
bukti(IdAturan, Tujuan, [SubBukti...])
fakta(Tujuan)
tidak(Tujuan)
```

`why_not/2` mengembalikan daftar `gagal(IdAturan, TujuanGagal)`, satu entri untuk
tiap klausa aturan yang kepalanya cocok dengan kueri.

## Video

Rekaman demo ada di Google Drive: _tautan menyusul_
