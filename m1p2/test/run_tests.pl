% run_tests.pl — menjalankan test/cq.json dan test/tests.json.
% Pakai: swipl test/run_tests.pl

:- use_module(library(json)).

:- initialization(main, main).
:- dynamic hasil/2.

main :-
    consult('src/kb.pl'),
    consult('src/abox.pl'),
    jalankan('test/cq.json'),
    jalankan('test/tests.json'),
    ringkas,
    halt.

jalankan(Berkas) :-
    setup_call_cleanup(open(Berkas, read, S, [encoding(utf8)]),
                       json_read_dict(S, Semua),
                       close(S)),
    length(Semua, N),
    format("~n== ~w (~w kasus) ==~n", [Berkas, N]),
    forall(member(K, Semua), uji(K)).

uji(K) :-
    Id = K.id,
    atom_string(Individu, K.kueri.individu),
    atom_string(Kelas, K.kueri.kelas),
    Harapan = K.harapan,
    Fakta = K.fakta,
    forall(member([S, P, O], Fakta), pasang(S, P, O)),
    (   catch(classify(Individu, Kelas), _, fail)
    ->  Hasil = true
    ;   Hasil = false
    ),
    (   Hasil == Harapan -> Status = lulus ; Status = gagal ),
    assertz(hasil(Id, Status)),
    format("~w  ~w  ~w(~w)  harapan=~w hasil=~w~n",
           [Id, Status, Kelas, Individu, Harapan, Hasil]),
    (   Status == gagal
    ->  (   catch(why_not(classify(Individu, Kelas), A), _, A = galat)
        ->  format("      gagal: ~q~n", [A])
        ;   true
        )
    ;   true
    ),
    forall(member([S, P, O], Fakta), lepas(S, P, O)).

nilai(O, N) :-
    (   number(O) -> N = O
    ;   atom_number(O, X) -> N = X
    ;   atom_string(N, O)
    ).

pasang(S, P, O) :-
    atom_string(SA, S), atom_string(PA, P), nilai(O, N),
    assertz(triple(SA, PA, N)).

lepas(S, P, O) :-
    atom_string(SA, S), atom_string(PA, P), nilai(O, N),
    retractall(triple(SA, PA, N)).

ringkas :-
    findall(Id, hasil(Id, lulus), Lulus),
    findall(Id, hasil(Id, gagal), Gagal),
    length(Lulus, NL), length(Gagal, NG),
    format("~n== RINGKASAN ==~n  lulus: ~w~n  gagal: ~w~n", [NL, NG]),
    (   Gagal == []
    ->  writeln("  semua kasus sesuai harapan")
    ;   format("  yang gagal: ~w~n", [Gagal])
    ).
