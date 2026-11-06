% run_tests.pl — menjalankan test/cq.json dan test/tests.json.
% Pakai: swipl test/run_tests.pl

:- use_module(library(json)).

:- initialization(main, main).
:- dynamic hasil/2.

main :-
    consult('src/kb.pl'),
    consult('src/abox.pl'),
    run_file('test/cq.json'),
    run_file('test/tests.json'),
    summary,
    halt.

run_file(Berkas) :-
    setup_call_cleanup(open(Berkas, read, S, [encoding(utf8)]),
                       json_read_dict(S, Semua),
                       close(S)),
    length(Semua, N),
    format("~n== ~w (~w kasus) ==~n", [Berkas, N]),
    forall(member(K, Semua), run_case(K)).

run_case(K) :-
    Id = K.id,
    atom_string(Individu, K.kueri.individu),
    atom_string(Kelas, K.kueri.kelas),
    Harapan = K.harapan,
    Fakta = K.fakta,
    forall(member([S, P, O], Fakta), add_fact(S, P, O)),
    (   catch(classify(Individu, Kelas), _, fail)
    ->  Hasil = true
    ;   Hasil = false
    ),
    (   Hasil == Harapan -> Status = passed ; Status = failed ),
    assertz(hasil(Id, Status)),
    format("~w  ~w  ~w(~w)  harapan=~w hasil=~w~n",
           [Id, Status, Kelas, Individu, Harapan, Hasil]),
    (   Status == failed
    ->  (   catch(why_not(classify(Individu, Kelas), A), _, A = galat)
        ->  format("      failed: ~q~n", [A])
        ;   true
        )
    ;   true
    ),
    forall(member([S, P, O], Fakta), drop_fact(S, P, O)).

value_of(O, N) :-
    (   number(O) -> N = O
    ;   atom_number(O, X) -> N = X
    ;   atom_string(N, O)
    ).

add_fact(S, P, O) :-
    atom_string(SA, S), atom_string(PA, P), value_of(O, N),
    assertz(triple(SA, PA, N)).

drop_fact(S, P, O) :-
    atom_string(SA, S), atom_string(PA, P), value_of(O, N),
    retractall(triple(SA, PA, N)).

summary :-
    findall(Id, hasil(Id, passed), Lulus),
    findall(Id, hasil(Id, failed), Gagal),
    length(Lulus, NL), length(Gagal, NG),
    format("~n== SUMMARY ==~n  passed: ~w~n  failed: ~w~n", [NL, NG]),
    (   Gagal == []
    ->  writeln("  all cases match expectations")
    ;   format("  failed: ~w~n", [Gagal])
    ).
