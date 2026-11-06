% run_tests.pl — menjalankan test/cq.json dan test/tests.json.
% Pakai: swipl test/run_tests.pl
%
% hanya kb.pl yang dimuat (tanpa abox.pl), lalu setiap kasus memasang
% fakta-nya sendiri dan dibersihkan setelahnya. Sebuah kasus lulus jika
% classify/2 sesuai harapan dalam 5 detik dan, untuk harapan false,
% setiap ID di why_not_wajib_menyebut muncul di why_not/2.

:- use_module(library(json)).
:- use_module(library(time)).

:- initialization(main, main).
:- dynamic hasil/2.

main :-
    consult('src/kb.pl'),
    run_file('test/cq.json'),
    run_file('test/tests.json'),
    summary.

run_file(Berkas) :-
    setup_call_cleanup(open(Berkas, read, S, [encoding(utf8)]),
                       json_read_dict(S, Semua),
                       close(S)),
    length(Semua, N),
    format("~n== ~w (~w kasus) ==~n", [Berkas, N]),
    forall(member(K, Semua), run_case(K)).

run_case(K) :-
    retractall(triple(_, _, _)),
    forall(member([S, P, O], K.fakta), add_fact(S, P, O)),
    atom_string(Individu, K.kueri.individu),
    atom_string(Kelas, K.kueri.kelas),
    Harapan = K.harapan,
    timed(classify(Individu, Kelas), Hasil),
    check_why_not(K, Individu, Kelas, Hasil, Catatan),
    (   Hasil == Harapan, Catatan == ok -> Status = passed ; Status = failed ),
    assertz(hasil(K.id, Status)),
    format("~w  ~w  ~w(~w)  harapan=~w hasil=~w~n",
           [K.id, Status, Kelas, Individu, Harapan, Hasil]),
    (   Catatan == ok -> true ; format("      ~w~n", [Catatan]) ),
    retractall(triple(_, _, _)).

% Hasil: true, false, timeout, atau galat(E)
timed(Goal, Hasil) :-
    catch(call_with_time_limit(5, (Goal -> Hasil = true ; Hasil = false)),
          E,
          ( E = time_limit_exceeded -> Hasil = timeout ; Hasil = galat(E) )).

check_why_not(K, Individu, Kelas, Hasil, Catatan) :-
    (   Hasil == false,
        get_dict(why_not_wajib_menyebut, K, Wajib0)
    ->  maplist([X, A]>>atom_string(A, X), Wajib0, Wajib),
        catch(call_with_time_limit(5, why_not(classify(Individu, Kelas), Alasan)),
              E, (Alasan = [], print_message(error, E))),
        findall(Id, member(gagal(Id, _), Alasan), Ids),
        subtract(Wajib, Ids, Hilang),
        (   Hilang == []
        ->  Catatan = ok
        ;   format(atom(Catatan), "why_not tidak menyebut ~w; keluaran: ~q", [Hilang, Alasan])
        )
    ;   Catatan = ok
    ).

% Setiap elemen fakta adalah teks term Prolog, misalnya "98" atau "date(2026,9,5)".
add_fact(S, P, O) :-
    term_string(ST, S), term_string(PT, P), term_string(OT, O),
    assertz(triple(ST, PT, OT)).

summary :-
    findall(Id, hasil(Id, passed), Lulus),
    findall(Id, hasil(Id, failed), Gagal),
    length(Lulus, NL), length(Gagal, NG),
    format("~n== SUMMARY ==~n  passed: ~w~n  failed: ~w~n", [NL, NG]),
    (   Gagal == []
    ->  writeln("  all cases match expectations"), halt(0)
    ;   format("  failed: ~w~n", [Gagal]), halt(1)
    ).
