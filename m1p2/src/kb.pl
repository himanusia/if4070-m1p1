% kb.pl — basis pengetahuan Part 2 (K11, mahjong riichi)
% Tidak memuat triple individu. Muat dengan: swipl kb.pl
%
% Kosakata triple yang dibaca aturan:
%   tangan : rdf_type player_hand, has_group G, has_pair P, has_tile T,
%            has_yaku Y, has_dora D, waiting_for T, dimainkan_oleh Pemain,
%            round_wind W, ruleset wrc
%   group  : rdf_type sequence|triplet|quad|pair|melded_group|concealed_group,
%            has_tile T
%   tile   : has_rank N, has_suit manzu|pinzu|souzu,
%            rdf_type honour_tile|wind_tile|dragon_tile|dora_tile, has_wind W
%   pemain : skor_meja S, di_meja M, seat_wind W
%
% Ruleset: house rules kelompok (R18, R19) berlaku secara bawaan. Tangan yang
% dinilai murni menurut WRC diberi triple(H, ruleset, wrc).

:- dynamic triple/3.
:- discontiguous aturan/3.

% ---------------------------------------------------------------------------
% META-INTERPRETER
% ---------------------------------------------------------------------------

body_goals((A, B), Goals) :- !,
    body_goals(A, GA), body_goals(B, GB), append(GA, GB, Goals).
body_goals(true, []) :- !.
body_goals(A, [A]).

rule_head(F/N) :- aturan(_, Kepala, _), functor(Kepala, F, N), !.

is_rule_goal(G) :- callable(G), functor(G, F, N), rule_head(F/N).

prove(true, fakta(true)) :- !.
prove((A, B), Bukti) :- !,
    body_goals((A, B), Goals), prove_list(Goals, Bukti).
prove(\+ G, tidak(G)) :- !, \+ prove(G, _).
prove(Goal, bukti(Id, Goal, Sub)) :-
    is_rule_goal(Goal), !,
    aturan(Id, Goal, Badan),
    body_goals(Badan, Goals),
    prove_list(Goals, Sub).
prove(Goal, fakta(Goal)) :-
    functor(Goal, F, N),
    catch(call(Goal),
          error(existence_error(procedure, PI), _),
          ( PI == F/N -> fail ; throw(error(existence_error(procedure, PI), _)) )).

prove_list([], []).
prove_list([G|Gs], [P|Ps]) :- prove(G, P), prove_list(Gs, Ps).

% ---------------------------------------------------------------------------
% ANTARMUKA
% ---------------------------------------------------------------------------

class_goal(Individu, Kelas, Goal) :-
    atom(Kelas),
    Goal =.. [Kelas, Individu].

classify(Individu, Kelas) :-
    class_goal(Individu, Kelas, Goal),
    once(prove(Goal, _)).

explain(classify(Individu, Kelas), Bukti) :-
    class_goal(Individu, Kelas, Goal),
    once(prove(Goal, Bukti)).

% why_not/2: elemen pertama daftar adalah gagal/2 untuk setiap klausa yang
% kepalanya cocok dengan kueri (sesuai kontrak). Setelahnya, untuk tujuan gagal
% yang juga kepala aturan, penelusuran turun sampai kedalaman 2 supaya alasan
% sebenarnya (misalnya pengecualian R19) ikut terlihat.
% Satu klausa menghasilkan satu gagal/2. Jika badan punya beberapa jalur
% (misalnya beberapa group), dipilih jalur yang paling jauh sebelum gagal.
why_not(classify(Individu, Kelas), Alasan) :-
    class_goal(Individu, Kelas, Goal),
    \+ prove(Goal, _),
    alasan(Goal, 0, Semua),
    dedup_variant(Semua, Alasan).

alasan(Goal, Depth, Alasan) :-
    findall(Id-(Kepala :- Badan),
            ( aturan(Id, Kepala, Badan), \+ Kepala \= Goal ),
            Klausa),
    findall(gagal(Id, Gagal),
            ( member(Id-(Kepala :- Badan), Klausa),
              clause_failure(Goal, Kepala, Badan, Gagal)
            ),
            Langsung),
    (   Depth >= 2
    ->  Alasan = Langsung
    ;   D1 is Depth + 1,
        findall(Sub,
                ( member(gagal(_, G), Langsung),
                  is_rule_goal(G),
                  alasan(G, D1, Sub)
                ),
                Subs),
        append([Langsung|Subs], Alasan)
    ).

clause_failure(Goal, Kepala, Badan, Gagal) :-
    findall(N-G,
            ( Kepala = Goal,
              body_goals(Badan, Goals),
              first_failure(Goals, 1, N, G) ),
            Semua),
    Semua \== [],
    aggregate_all(max(N), member(N-_, Semua), Maks),
    once(member(Maks-Gagal, Semua)).

first_failure([G|_], N, N, G) :- \+ prove(G, _), !.
first_failure([G|Gs], I, N, Gagal) :-
    prove(G, _), I1 is I + 1, first_failure(Gs, I1, N, Gagal).

dedup_variant([], []).
dedup_variant([X|Xs], [X|Ys]) :-
    exclude(=@=(X), Xs, Sisa),
    dedup_variant(Sisa, Ys).

% ---------------------------------------------------------------------------
% PEMBANTU DAN FAKTA STATIK (bukan aturan domain)
% ---------------------------------------------------------------------------

distinct_count(Template, Goal, N) :-
    findall(Template, Goal, L), sort(L, S), length(S, N).

tile_count(H, N) :- distinct_count(T, triple(H, has_tile, T), N).
pair_count(H, N) :- distinct_count(P, triple(H, has_pair, P), N).
dora_count(H, N) :- distinct_count(D, triple(H, has_dora, D), N).

% R6/R7: setiap has_group dihitung satu group (quad juga satu), tetapi objek
% yang terbukti pair lewat r7 tidak dihitung sebagai group.
group_count(H, N) :-
    distinct_count(G, ( triple(H, has_group, G), \+ prove(pair(G), _) ), N).

tiles_of(G, Ts) :- findall(T, triple(G, has_tile, T), L), sort(L, Ts).

% Jenis tile: suit-rank untuk tile bernomor, has_wind/tile_kind untuk honour.
tile_kind(T, S-R) :- triple(T, has_suit, S), triple(T, has_rank, R), !.
tile_kind(T, K)   :- triple(T, has_wind, K), !.
tile_kind(T, K)   :- triple(T, tile_kind, K), !.
tile_kind(T, T).

same_kind(Ts) :- maplist(tile_kind, Ts, Ks), sort(Ks, [_]).

same_suit(Ts) :-
    maplist([T, S]>>triple(T, has_suit, S), Ts, Ss), sort(Ss, [_]).

% R5 non-OWL: tiga rank berurutan; 8-9-1 tidak lolos karena 1, 8, 9 tidak
% berurutan (tidak ada aritmetika modulo / melingkar).
consecutive_ranks(Ts) :-
    maplist([T, R]>>triple(T, has_rank, R), Ts, Rs),
    msort(Rs, [A, B, C]),
    B =:= A + 1, C =:= B + 1.

copies_held(H, W, N) :-
    tile_kind(W, K),
    distinct_count(T, ( triple(H, has_tile, T), tile_kind(T, K) ), N).

identical_group(G) :- triple(G, rdf_type, triplet), !.
identical_group(G) :- prove(quad(G), _).

% Yaku bawaan: Id, kelas yaku di ontologi, nilai han.
yaku_bawaan(y_tanyao,       tanyao,        1).
yaku_bawaan(y_yakuhai,      yakuhai,       1).
yaku_bawaan(y_fullstraight, full_straight, 2).
yaku_bawaan(y_alltriplets,  all_triplets,  2).

kelas_yaku(K) :- yaku_bawaan(_, K, _).

yaku_kind(Y, K) :- yaku_bawaan(Y, K, _).
yaku_kind(Y, K) :- triple(Y, rdf_type, K), kelas_yaku(K).

yaku_han_value(Y, V) :- triple(Y, han_value, V), !.
yaku_han_value(Y, V) :- yaku_bawaan(Y, _, V), !.
yaku_han_value(_, 1).

% Jumlah han dari seluruh yaku berbeda yang terbukti lewat yaku_tangan/2.
yaku_han(H, Han) :-
    findall(Y, prove(yaku_tangan(H, Y), _), Ys0),
    sort(Ys0, Ys),
    maplist(yaku_han_value, Ys, Vs),
    sum_list(Vs, Han).

% ---------------------------------------------------------------------------
% ATURAN DOMAIN
% ---------------------------------------------------------------------------

% R1 — tangan pemain
aturan(r1, player_hand(H), triple(H, rdf_type, player_hand)).

% R2, R3 — terminal dan inside (saling lepas karena rentang rank tidak beririsan)
aturan(r2, terminal_tile(T),
       ( triple(T, has_rank, R), (R =:= 1 ; R =:= 9) )).

aturan(r3, inside_tile(T),
       ( triple(T, has_rank, R), R >= 2, R =< 8 )).

% R4 — honour = wind ⊔ dragon
aturan(r4, honour_tile(T), triple(T, rdf_type, honour_tile)).
aturan(r4, honour_tile(T), triple(T, rdf_type, wind_tile)).
aturan(r4, honour_tile(T), triple(T, rdf_type, dragon_tile)).

% R5 (non-OWL) — sequence: tiga tile satu suit, berurutan, tanpa honour,
% tidak melingkar 9→1. Klausa pertama dipakai hanya bila tile group tidak
% diketahui (info tak lengkap), sehingga asersi tipe tidak bisa menimpa cek tile.
aturan(r5, sequence(G),
       ( triple(G, rdf_type, sequence), \+ triple(G, has_tile, _) )).
aturan(r5, sequence(G),
       ( tiles_of(G, Ts), length(Ts, 3),
         \+ ( member(T, Ts), honour_tile(T) ),
         same_suit(Ts),
         consecutive_ranks(Ts) )).

% R6 — quad: empat tile identik (dihitung satu group, lihat group_count/2)
aturan(r6, quad(G), triple(G, rdf_type, quad)).
aturan(r6, quad(G),
       ( tiles_of(G, Ts), length(Ts, 4), same_kind(Ts) )).

% R7 — pair: dua tile identik, bukan group
aturan(r7, pair(P), triple(P, rdf_type, pair)).
aturan(r7, pair(P),
       ( tiles_of(P, Ts), length(Ts, 2), same_kind(Ts) )).

% R8 — open / closed
aturan(r8, open_hand(H),
       ( player_hand(H),
         triple(H, has_group, G), triple(G, rdf_type, melded_group) )).
aturan(r8, closed_hand(H),
       ( player_hand(H),
         \+ ( triple(H, has_group, G), triple(G, rdf_type, melded_group) ) )).

% R9 — valid: 4 group + 1 pair, tujuh pair, atau Thirteen Orphans
aturan(r9, valid_hand(H),
       ( player_hand(H), group_count(H, 4), pair_count(H, 1) )).
aturan(r9, valid_hand(H), seven_pairs_hand(H)).
aturan(r9, valid_hand(H), thirteen_orphans_hand(H)).
aturan(r9, seven_pairs_hand(H),
       ( player_hand(H), pair_count(H, 7) )).
aturan(r9, thirteen_orphans_hand(H),
       ( player_hand(H), triple(H, rdf_type, thirteen_orphans_hand) )).

% R10 — menang: valid dan punya minimal satu yaku
aturan(r10, winning_hand(H),
       ( valid_hand(H), yaku_tangan(H, _) )).

% Yaku yang diasersikan langsung (selain Tan'yao, yang tunduk pada R19)
aturan(r10, yaku_tangan(H, Y),
       ( triple(H, has_yaku, Y), yaku_sah(Y), \+ yaku_kind(Y, tanyao) )).

% R11 (non-OWL) — tenpai: 13 tile, menunggu satu tile yang masih mungkin ada
aturan(r11, tenpai_hand(H),
       ( player_hand(H), tile_count(H, 13),
         triple(H, waiting_for, W), tile_masih_ada(H, W) )).
aturan(r11, tile_masih_ada(H, W),
       ( copies_held(H, W, N), N < 4 )).

% R12 — Tan'yao: seluruh tile inside. Pola tangan = TanyaoPattern di ontologi;
% kelas yaku = Tanyao.
aturan(r12, tanyao_pattern(H),
       ( player_hand(H), tile_count(H, N), N >= 13,
         \+ ( triple(H, has_tile, T), \+ inside_tile(T) ) )).
aturan(r12, tanyao(Y), yaku_kind(Y, tanyao)).
aturan(r12, yaku_tangan(H, y_tanyao),
       ( tanyao_pattern(H), tanyao_bernilai(H) )).
aturan(r12, yaku_tangan(H, Y),
       ( triple(H, has_yaku, Y), yaku_kind(Y, tanyao), tanyao_bernilai(H) )).

% R19 (twist) — Tan'yao hanya bernilai pada tangan closed; pada tangan open
% hanya bernilai bila tangan dinilai menurut WRC. Menggantikan R12 untuk open.
aturan(r19, tanyao_bernilai(H), closed_hand(H)).
aturan(r19, tanyao_bernilai(H), triple(H, ruleset, wrc)).

% R13 — Yakuhai: triplet/quad dragon, seat wind, atau round wind
aturan(r13, yakuhai(Y), yaku_kind(Y, yakuhai)).
aturan(r13, yaku_tangan(H, y_yakuhai), punya_yakuhai(H)).
aturan(r13, punya_yakuhai(H),
       ( triple(H, has_group, G), identical_group(G),
         triple(G, has_tile, T), triple(T, rdf_type, dragon_tile) )).
aturan(r13, punya_yakuhai(H),
       ( triple(H, has_group, G), identical_group(G),
         triple(G, has_tile, T), triple(T, has_wind, W),
         triple(H, dimainkan_oleh, P), triple(P, seat_wind, W) )).
aturan(r13, punya_yakuhai(H),
       ( triple(H, has_group, G), identical_group(G),
         triple(G, has_tile, T), triple(T, has_wind, W),
         triple(H, round_wind, W) )).

% R14 — dora bukan yaku
aturan(r14, yaku_sah(Y),
       ( \+ triple(Y, rdf_type, dora_tile), yaku_kind(Y, _) )).

% R15 — setiap dora menambah 1 han
aturan(r15, tambahan_han_dora(H, N), dora_count(H, N)).

% R16 (non-OWL) — total han = han yaku + dora + bonus
aturan(r16, total_han(H, Total),
       ( winning_hand(H),
         yaku_han(H, HY),
         tambahan_han_dora(H, HD),
         han_bonus(H, HB),
         Total is HY + HD + HB )).

% R17 — kategori menurut total han
aturan(r17, kategori_han(T, mangan),    T =:= 5).
aturan(r17, kategori_han(T, haneman),   ( T >= 6,  T =< 7  )).
aturan(r17, kategori_han(T, baiman),    ( T >= 8,  T =< 10 )).
aturan(r17, kategori_han(T, sanbaiman), ( T >= 11, T =< 12 )).
aturan(r17, kategori_han(T, yonbaiman), T >= 13).

aturan(r17, mangan_hand(H),    ( total_han(H, T), kategori_han(T, mangan) )).
aturan(r17, haneman_hand(H),   ( total_han(H, T), kategori_han(T, haneman) )).
aturan(r17, baiman_hand(H),    ( total_han(H, T), kategori_han(T, baiman) )).
aturan(r17, sanbaiman_hand(H), ( total_han(H, T), kategori_han(T, sanbaiman) )).
aturan(r17, yonbaiman_hand(H), ( total_han(H, T), kategori_han(T, yonbaiman) )).

% R18 (non-OWL, twist) — Bonus Comeback: pemenang (sudah punya yaku) yang skor
% mejanya terendah di antara pemain di meja yang sama mendapat +1 han.
aturan(r18, bonus_comeback(H),
       ( winning_hand(H),
         \+ triple(H, ruleset, wrc),
         triple(H, dimainkan_oleh, P),
         skor_meja_terendah(P) )).
aturan(r18, skor_meja_terendah(P),
       ( triple(P, skor_meja, S), triple(P, di_meja, M),
         \+ ( triple(Q, di_meja, M), Q \== P,
              triple(Q, skor_meja, SQ), SQ < S ) )).
aturan(r18, han_bonus(H, 1), bonus_comeback(H)).
aturan(r18, han_bonus(H, 0), \+ bonus_comeback(H)).
