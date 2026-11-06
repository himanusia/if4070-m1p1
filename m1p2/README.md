# Milestone 1 Part 2 — K11 (Mahjong)

Translation of the Part 1 OWL/DL knowledge base into SWI-Prolog, with a
meta-interpreter that builds proof trees from `aturan/3` clauses.

## Running

Requires SWI-Prolog 9 or newer.

```
./run.sh                   # interactive session, kb.pl + abox.pl preloaded
./demo.sh                  # print all twelve CQ answers, then exit
swipl test/run_tests.pl    # run cq.json + tests.json
swipl src/kb.pl            # must load alone, with no individual triples
```

## Layout

| File | Contents |
|---|---|
| `src/kb.pl` | meta-interpreter, interface (`classify/2`, `explain/2`, `why_not/2`), the 19 domain rules as `aturan/3`. No individual triples. |
| `src/abox.pl` | every individual as `triple/3` |
| `src/main.pl` | entry point: loads kb + abox, runs the CQs |
| `test/cq.json` | the 12 CQs and their cases |
| `test/tests.json` | 16 test cases across 6 categories |
| `test/run_tests.pl` | runner that compares results against `harapan` |

## Interface

```prolog
?- classify(tangan_cq8, winning_hand).
?- explain(classify(tangan_cq8, winning_hand), Proof).
?- why_not(classify(tangan_tanpa_yaku, winning_hand), Reasons).
```

Proof shape:

```
bukti(RuleId, Goal, [SubProof...])
fakta(Goal)
tidak(Goal)
```

`why_not/2` returns a list of `gagal(RuleId, FailedGoal)`, one entry for every
rule clause whose head matches the query.

Interface names are Indonesian because the specification fixes them; everything
else in the code is English.

## Video

Demo recording: _link pending_
