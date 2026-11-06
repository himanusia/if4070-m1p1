% case.pl — muat kb.pl saja, lalu suntik fakta satu kasus dari test/cq.json.
% Inilah bentuk yang dipakai asisten saat ujian: kb.pl tanpa individu,
% individunya ditambahkan sendiri lewat triple/3.
%
% Pakai: swipl -q -s test/case.pl -- CQ8 [tree]

:- use_module(library(json)).
:- initialization(main, main).

main :-
    consult('src/kb.pl'),
    current_prolog_flag(argv, Argv),
    Argv = [Id0|Opsi],
    atom_string(Id, Id0),
    muat(Id),
    kueri(Id, Opsi),
    halt.

muat(Id) :-
    baca(Semua),
    (   member(K, Semua), atom_string(KId, K.id), KId == Id
    ->  forall(member([A, B, C], K.fakta), add_fact(A, B, C))
    ;   format("kasus ~w tidak ada di test/cq.json~n", [Id]),
        halt(1)
    ).

baca(Semua) :-
    setup_call_cleanup(open('test/cq.json', read, S, [encoding(utf8)]),
                       json_read_dict(S, Semua),
                       close(S)).

add_fact(A, B, C) :-
    atom_string(SA, A), atom_string(PB, B),
    (   number(C) -> Nilai = C ; atom_number(C, X) -> Nilai = X ; atom_string(Nilai, C) ),
    assertz(triple(SA, PB, Nilai)).

kueri(Id, Opsi) :-
    baca(Semua),
    (   member(K, Semua), atom_string(KId, K.id), KId == Id
    ->  atom_string(I, K.kueri.individu),
        atom_string(C, K.kueri.kelas),
        perintah(Opsi, Tree),
        format("~w: ~w(~w)?~n", [Id, C, I]),
        (   explain(classify(I, C), Bukti)
        ->  format("YA~n"), cetak(Bukti, Tree)
        ;   why_not(classify(I, C), Alasan),
            format("TIDAK~n"), cetak(Alasan, Tree)
        )
    ;   true
    ).

perintah(Opsi, true) :- memberchk(tree, Opsi), !.
perintah(_, false).

cetak(P, true) :- !, pohon(P, 0).
cetak(P, false) :- format("~q~n", [P]).

pohon(List, D) :- is_list(List), !, forall(member(E, List), pohon(E, D)).
pohon(bukti(Id, Goal, Subs), D) :-
    !,
    indent(D), format("bukti(~w, ~q, [~n", [Id, Goal]),
    D1 is D + 2,
    forall(member(S, Subs), pohon(S, D1)),
    indent(D), writeln("])").
pohon(fakta(G), D) :- !, indent(D), format("fakta(~q)~n", [G]).
pohon(tidak(G), D) :- !, indent(D), format("tidak((~q))~n", [G]).
pohon(X, D) :- indent(D), format("~q~n", [X]).

indent(0) :- !.
indent(N) :- N > 0, write('  '), N1 is N - 1, indent(N1).
