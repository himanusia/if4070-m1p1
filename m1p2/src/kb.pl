% kb.pl — basis pengetahuan Part 2 (K11, mahjong riichi)
% Tidak memuat triple individu. Muat dengan: swipl kb.pl

:- dynamic triple/3.
:- discontiguous aturan/3.

% ---------------------------------------------------------------------------
% META-INTERPRETER
% ---------------------------------------------------------------------------

body_goals((A, B), [A|Sisa]) :- !, body_goals(B, Sisa).
body_goals(true, []) :- !.
body_goals(A, [A]).

kepala_aturan(F/N) :- aturan(_, Kepala, _), functor(Kepala, F, N).

prove(true, fakta(true)) :- !.
prove((A, B), gabung(PA, PB)) :- !, prove(A, PA), prove(B, PB).
prove(\+(G), tidak(\+(G))) :- !, \+ prove(G, _).
prove(Goal, bukti(Id, Goal, Sub)) :-
    aturan(Id, Kepala, Badan),
    Kepala = Goal,
    body_goals(Badan, Goals),
    prove_list(Goals, Sub).
prove(Goal, fakta(Goal)) :-
    functor(Goal, F, N),
    \+ kepala_aturan(F/N),
    call(Goal).

prove_list([], []).
prove_list([G|Gs], [P|Ps]) :- prove(G, P), prove_list(Gs, Ps).

% ---------------------------------------------------------------------------
% ANTARMUKA
% ---------------------------------------------------------------------------

classify(Individu, Kelas) :-
    Goal =.. [Kelas, Individu],
    prove(Goal, _).

explain(classify(Individu, Kelas), Bukti) :-
    Goal =.. [Kelas, Individu],
    prove(Goal, Bukti).

why_not(classify(Individu, Kelas), Alasan) :-
    Goal =.. [Kelas, Individu],
    \+ prove(Goal, _),
    findall(gagal(Id, Gagal),
            ( aturan(Id, Kepala, Badan),
              Kepala = Goal,
              body_goals(Badan, Goals),
              gagal_pertama(Goals, Gagal)
            ),
            Alasan).

gagal_pertama([G|_], G) :- \+ prove(G, _), !.
gagal_pertama([G|Gs], Gagal) :- prove(G, _), gagal_pertama(Gs, Gagal).

% ---------------------------------------------------------------------------
% PEMBANTU (bukan aturan domain)
% ---------------------------------------------------------------------------

jumlah_group(H, N) :- findall(G, triple(H, has_group, G), L), length(L, N).
jumlah_pair(H, N)  :- findall(P, triple(H, has_pair, P), L), length(L, N).
jumlah_tile(H, N)  :- findall(T, triple(H, has_tile, T), L), length(L, N).
jumlah_dora(H, N)  :- findall(D, triple(H, has_dora, D), L), length(L, N).
ada_group_melded(H) :- triple(H, has_group, G), triple(G, rdf_type, melded_group).

% ---------------------------------------------------------------------------
% ATURAN DOMAIN
% ---------------------------------------------------------------------------

aturan(r1, player_hand(H), triple(H, rdf_type, player_hand)).

aturan(r2, terminal_tile(T),
       ( triple(T, has_rank, R), (R =:= 1 ; R =:= 9) )).

aturan(r3, inside_tile(T),
       ( triple(T, has_rank, R), R >= 2, R =< 8 )).

aturan(r4, honour_tile(T), triple(T, rdf_type, honour_tile)).

aturan(r5, sequence(G), triple(G, rdf_type, sequence)).

aturan(r6, quad(G), triple(G, rdf_type, quad)).

aturan(r7, pair(P), triple(P, rdf_type, pair)).

aturan(r8, closed_hand(H),
       ( player_hand(H), \+ ada_group_melded(H) )).

aturan(r8, open_hand(H),
       ( player_hand(H), ada_group_melded(H) )).

aturan(r9, valid_hand(H),
       ( player_hand(H), jumlah_group(H, N), N >= 4,
         jumlah_pair(H, P), P >= 1 )).

aturan(r10, winning_hand(H),
       ( valid_hand(H), triple(H, has_yaku, _) )).

% Klausa kedua: tanyao adalah yaku, jadi tangan yang memenuhinya menang
% walaupun tidak ada triple has_yaku. Ini rantai yang dipakai CQ8.
aturan(r10, winning_hand(H),
       ( valid_hand(H), tanyao(H) )).

aturan(r11, tenpai_hand(H),
       ( player_hand(H), triple(H, waiting_for, _),
         jumlah_tile(H, N), N =:= 13 )).

aturan(r12, tanyao(H),
       ( player_hand(H),
         jumlah_tile(H, N), N >= 13,
         \+ ( triple(H, has_tile, T), \+ inside_tile(T) ) )).

aturan(r13, yakuhai(H), triple(H, has_yaku, y_yakuhai)).

aturan(r14, dora_bukan_yaku(D),
       ( triple(D, rdf_type, dora_tile), \+ triple(D, rdf_type, yaku) )).

aturan(r15, tambahan_han_dora(H, N),
       ( jumlah_dora(H, N), N > 0 )).

aturan(r16, total_han(H, Total),
       ( winning_hand(H),
         findall(V, ( triple(H, has_yaku, Y), triple(Y, han_value, V) ), NV),
         sum_list(NV, HYaku),
         jumlah_dora(H, HD),
         Total is HYaku + HD )).

aturan(r17, kategori_han(Total, mangan),   ( Total >= 5,  Total =< 5  )).
aturan(r17, kategori_han(Total, haneman),  ( Total >= 6,  Total =< 7  )).
aturan(r17, kategori_han(Total, baiman),   ( Total >= 8,  Total =< 10 )).
aturan(r17, kategori_han(Total, sanbaiman), (Total >= 11, Total =< 12 )).
aturan(r17, kategori_han(Total, yonbaiman), (Total >= 13 )).

aturan(r18, bonus_comeback(H),
       ( winning_hand(H), triple(H, skor_meja_terendah, ya) )).

aturan(r19, tanyao_open(H),
       ( open_hand(H), tanyao(H) )).
