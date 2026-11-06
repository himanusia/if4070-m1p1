% case.pl — muat kb.pl saja, lalu suntik fakta satu kasus dari test/cq.json.
% Inilah bentuk yang dipakai asisten saat ujian: kb.pl tanpa individu,
% individunya ditambahkan sendiri lewat triple/3.
%
% Pakai: swipl -q -s test/case.pl -- CQ8

:- use_module(library(json)).
:- initialization(main, main).

main :-
    consult('src/kb.pl'),
    current_prolog_flag(argv, [Id0]),
    atom_string(Id, Id0),
    muat(Id),
    kueri(Id),
    halt.

muat(Id) :-
    setup_call_cleanup(open('test/cq.json', read, S, [encoding(utf8)]),
                       json_read_dict(S, Semua),
                       close(S)),
    (   member(K, Semua), atom_string(KId, K.id), KId == Id
    ->  forall(member([A, B, C], K.fakta), add_fact(A, B, C))
    ;   format("kasus ~w tidak ada di test/cq.json~n", [Id]),
        halt(1)
    ).

add_fact(A, B, C) :-
    atom_string(SA, A), atom_string(PB, B),
    (   number(C) -> Nilai = C ; atom_number(C, X) -> Nilai = X ; atom_string(Nilai, C) ),
    assertz(triple(SA, PB, Nilai)).

kueri(Id) :-
    setup_call_cleanup(open('test/cq.json', read, S, [encoding(utf8)]),
                       json_read_dict(S, Semua),
                       close(S)),
    (   member(K, Semua), atom_string(KId, K.id), KId == Id
    ->  atom_string(I, K.kueri.individu),
        atom_string(C, K.kueri.kelas),
        format("~w: ~w(~w)?~n", [Id, C, I]),
        (   explain(classify(I, C), Bukti)
        ->  format("YA~n~q~n", [Bukti])
        ;   why_not(classify(I, C), Alasan),
            format("TIDAK~n~q~n", [Alasan])
        )
    ;   true
    ).
