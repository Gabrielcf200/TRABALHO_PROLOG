/*  testes.pl — testes plunit do núcleo.
    Uso: swipl -g run_tests -t halt testes/testes.pl
*/
:- use_module(library(plunit)).
:- use_module('../src/estacoes').
:- use_module('../src/operacao').
:- use_module('../src/roteador').

:- begin_tests(esqueleto).

test(modulos_carregados) :-
    current_module(estacoes),
    current_module(operacao),
    current_module(roteador).

:- end_tests(esqueleto).

/*  Etapa 01 — base de dados (critérios de etapas/01-base-de-dados.md) */
:- begin_tests(estacoes).

test(posicoes_sem_buraco_nem_repeticao, forall(ramal(R, _))) :-
    findall(P, estacao_ramal(_, R, P), Ps),
    length(Ps, N), N > 1,
    numlist(1, N, Esperado),
    msort(Ps, Esperado).

test(estacao_nao_repete_no_ramal, forall(ramal(R, _))) :-
    findall(E, estacao_ramal(E, R, _), Es),
    sort(Es, Unicas),
    length(Es, N), length(Unicas, N).

% Japeri e Santa Cruz têm o tronco do deodoro + silva_freire, na mesma ordem.
test(tronco_igual_em_deodoro_japeri_santa_cruz, [nondet, forall(member(R, [japeri, santa_cruz]))]) :-
    findall(E, estacao_ramal(E, deodoro, _), Tronco),
    estacao_ramal(deodoro, R, PD),
    findall(E, ( between(1, PD, P), estacao_ramal(E, R, P), E \== silva_freire ), TroncoR),
    TroncoR == Tronco.

test(integracao_em_dois_ramais, forall(integracao(E))) :-
    findall(R, estacao_ramal(E, R, _), Rs),
    sort(Rs, Unicos),
    length(Unicos, N), N >= 2.

test(extensao_comeca_na_conexao, [nondet, forall(extensao_de(X, Pai, Conexao))]) :-
    estacao_ramal(Conexao, X, 1),
    estacao_ramal(Conexao, Pai, _).

test(bairro_aponta_para_estacao_real, forall(bairro_estacao(_, E))) :-
    estacao_existe(E).

test(apelido_aponta_para_estacao_real, forall(apelido(_, E))) :-
    estacao_existe(E).

test(terminais, [nondet]) :-
    terminal(santa_cruz, santa_cruz),
    terminal(japeri, japeri),
    terminal(belford_roxo, belford_roxo),
    terminal(saracuruna, saracuruna),
    terminal(paracambi, paracambi).

test(vizinhas_em_ordem, [nondet]) :-
    vizinhas(deodoro, madureira, oswaldo_cruz),
    \+ vizinhas(deodoro, oswaldo_cruz, madureira).

test(resolver_estacao) :-
    resolver_local(meier, R), R == ok(estacao(meier)).

test(resolver_bairro) :-
    resolver_local(centro, R), R == ok(estacao(central_do_brasil)).

test(resolver_apelido) :-
    resolver_local(olimpica_de_engenho_de_dentro, R),
    R == ok(estacao(engenho_de_dentro)).

test(resolver_desconhecido) :-
    resolver_local(xyz, R), R == erro(local_desconhecido(xyz)).

test(resolver_nao_atomo) :-
    resolver_local(42, R), R == erro(local_desconhecido(42)).

:- end_tests(estacoes).
