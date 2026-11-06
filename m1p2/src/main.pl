% main.pl — titik masuk. Memuat kb.pl + abox.pl lalu menjalankan kueri demo.
% Pakai: swipl main.pl

:- use_module(library(json)).

:- initialization(main, main).

main :-
    consult('src/kb.pl'),
    consult('src/abox.pl'),
    count_of(aturan(_, _, _), A),
    count_of(triple(_, _, _), T),
    format("KB: ~w klausa aturan, ~w triple~n", [A, T]),
    run_cq,
    halt.

count_of(Goal, N) :- aggregate_all(count, Goal, N).

run_cq :-
    setup_call_cleanup(open('test/cq.json', read, S, [encoding(utf8)]),
                       json_read_dict(S, Kasus),
                       close(S)),
    forall(member(K, Kasus), satu(K)).

satu(K) :-
    atom_string(I, K.kueri.individu),
    atom_string(C, K.kueri.kelas),
    format("~n~w: ~w(~w)?~n", [K.id, C, I]),
    (   explain(classify(I, C), Bukti)
    ->  format("  YA~n  ~q~n", [Bukti])
    ;   why_not(classify(I, C), Alasan),
        format("  TIDAK~n  ~q~n", [Alasan])
    ).
