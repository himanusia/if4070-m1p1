# Milestone 1 Part 2 — K11 (Mahjong)

Translation of the Part 1 OWL/DL knowledge base into SWI-Prolog, with a
meta-interpreter that builds proof trees from `aturan/3` clauses.

## Running

Requires SWI-Prolog 9 or newer.

```
./case.sh CQ8              # one case: kb.pl only + that case's facts, prints proof
./run.sh                   # interactive session, kb.pl + abox.pl preloaded
./demo.sh                  # print every CQ case (explain / why_not), then exit
swipl test/run_tests.pl    # run cq.json + tests.json against kb.pl ONLY
swipl src/kb.pl            # must load alone, with no individual triples
```

## Layout

| File | Contents |
|---|---|
| `src/kb.pl` | meta-interpreter, interface (`classify/2`, `explain/2`, `why_not/2`), the 19 domain rules as `aturan/3`. No individual triples. |
| `src/abox.pl` | every individual as `triple/3` |
| `src/main.pl` | entry point: loads kb + abox, runs the CQs |
| `test/cq.json` | every CQ as self-contained cases (CQ1–CQ12, with a/b splits) |
| `test/tests.json` | 22 own test cases across all 6 categories, 12 with `harapan: false` |
| `test/run_tests.pl` | runner |

## Interface

```prolog
% from abox.pl
?- classify(tangan_tanpa_yaku, valid_hand).          % true
?- why_not(classify(tangan_tanpa_yaku, winning_hand), R).
?- explain(classify(tangan_tanyao_closed, winning_hand), Proof).

% a test case: kb.pl alone plus that case's facts
?- halt.
$ ./case.sh CQ8
```

Proof shape:

```
bukti(RuleId, Goal, [SubProof...])
fakta(Goal)
tidak(Goal)
```

`why_not/2` returns a list of `gagal(RuleId, FailedGoal)`. The first entries
are one per rule clause whose head matches the query (the first body goal that
fails). After that, failed goals that are themselves rule heads are traced up
to two levels deeper, so exceptions such as R19 show up by ID.

## Triple vocabulary and ruleset

Hands: `rdf_type player_hand`, `has_group`, `has_pair`, `has_tile`, `has_yaku`,
`has_dora`, `waiting_for`, `dimainkan_oleh`, `round_wind`, `ruleset`.
Groups: `rdf_type sequence|triplet|quad|pair|melded_group`, `has_tile`.
Tiles: `has_rank`, `has_suit` (`manzu|pinzu|souzu`), `rdf_type
wind_tile|dragon_tile|honour_tile|dora_tile`, `has_wind`.
Players: `skor_meja`, `di_meja`, `seat_wind`.

The group's house rules (R18 Bonus Comeback, R19 closed-only Tan'yao) apply by
default. A hand judged purely by WRC rules carries `triple(H, ruleset, wrc)`;
that is how CQ8 (WRC, yes) and CQ12 (house rules, no) differ on the same hand.

Interface names are Indonesian because the specification fixes them; everything
else in the code is English.

## Video

Demo recording: https://drive.google.com/file/d/1BDcKePC-NBk54fVDyI9Jz7vMyyrQ-Hx0/view
