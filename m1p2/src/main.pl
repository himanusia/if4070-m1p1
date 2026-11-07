% main.pl — titik masuk. Memuat kb.pl + abox.pl lalu menjalankan seluruh CQ.
% Pakai: swipl main.pl
%
% Setiap kasus di cq.json memasang fakta-nya sendiri. Nama individunya
% (cq8_tangan, dst.) tidak bertabrakan dengan individu abox.pl, dan fakta itu
% dicabut lagi setelah kasus selesai.

:- use_module(library(json)).

:- initialization(main, main).

main :-
    consult('src/kb.pl'),
    consult('src/abox.pl'),
    count_of(aturan(_, _, _), A),
    count_of(triple(_, _, _), T),
    format("KB: ~w klausa aturan, ~w triple abox~n", [A, T]),
    run_cq,
    halt.

count_of(Goal, N) :- aggregate_all(count, Goal, N).

run_cq :-
    setup_call_cleanup(open('test/cq.json', read, S, [encoding(utf8)]),
                       json_read_dict(S, Kasus),
                       close(S)),
    forall(member(K, Kasus), satu(K)).

satu(K) :-
    findall(triple(ST, PT, OT),
            ( member([S, P, O], K.fakta),
              term_string(ST, S), term_string(PT, P), term_string(OT, O) ),
            Fakta),
    maplist(assertz, Fakta),
    atom_string(I, K.kueri.individu),
    atom_string(C, K.kueri.kelas),
    format("~n~w: ~w(~w)?~n", [K.id, C, I]),
    (   explain(classify(I, C), Bukti)
    ->  writeln("  YA"), print_term(Bukti, []), nl
    ;   why_not(classify(I, C), Alasan),
        writeln("  TIDAK"),
        forall(member(X, Alasan), format("    ~q~n", [X]))
    ),
    forall(member(F, Fakta), retract(F)).
