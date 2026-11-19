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

/*  Etapa 02 — operação (critérios de etapas/02-operacao.md) */
:- begin_tests(operacao).

test(japeri_expresso_no_pico_util) :-
    modo(japeri, segunda_a_sexta, hora(7, 30), M), M == expresso.

test(japeri_parador_no_sabado) :-
    modo(japeri, sabado, hora(7, 30), M), M == parador.

test(japeri_expresso_no_horario_comercial) :-
    modo(japeri, segunda_a_sexta, hora(12, 0), M), M == expresso.

test(japeri_parador_a_noite_util) :-
    modo(japeri, segunda_a_sexta, hora(21, 30), M), M == parador.

test(belford_roxo_fecha_mais_cedo_no_domingo) :-
    \+ em_operacao(belford_roxo, domingo_feriado, hora(18, 0)),
    em_operacao(deodoro, domingo_feriado, hora(18, 0)).

test(faixa_de_pico) :-
    faixa_atual(segunda_a_sexta, hora(7, 0), P), P == pico,
    faixa_atual(segunda_a_sexta, hora(12, 0), V), V == vale,
    faixa_atual(sabado, hora(7, 0), S), S == vale.

test(deodoro_sempre_parador, forall(member(H, [hora(7,30), hora(12,0)]))) :-
    modo(deodoro, segunda_a_sexta, H, M), M == parador.

test(expresso_pula_piedade) :-
    \+ para_em(japeri, piedade, segunda_a_sexta, hora(7, 30)).

test(expresso_para_em_madureira, [nondet]) :-
    para_em(japeri, madureira, segunda_a_sexta, hora(7, 30)).

test(expresso_para_em_todas_depois_de_deodoro, [nondet]) :-
    para_em(japeri, nilopolis, segunda_a_sexta, hora(7, 30)).

test(parador_no_sabado_para_em_piedade, [nondet]) :-
    para_em(japeri, piedade, sabado, hora(10, 0)).

test(deodoro_para_em_piedade_quando_roda,
     [nondet, forall(member(D-H, [segunda_a_sexta-hora(7,30), sabado-hora(10,0), domingo_feriado-hora(15,0)]))]) :-
    para_em(deodoro, piedade, D, H).

test(fechado_de_madrugada) :-
    \+ em_operacao(deodoro, segunda_a_sexta, hora(2, 0)).

test(fim_da_janela_exclusivo) :-
    operacao(deodoro, segunda_a_sexta, _, Fim),
    \+ em_operacao(deodoro, segunda_a_sexta, Fim).

test(proxima_abertura_de_madrugada) :-
    proxima_abertura(segunda_a_sexta, hora(2, 0), A), A == abre(hora(4, 30)).

test(proxima_abertura_depois_do_ultimo_trem) :-
    proxima_abertura(segunda_a_sexta, hora(23, 30), A), A == abre(hora(4, 30)).

test(intervalo_definido_para_todos, [forall((ramal(R, _), dia(D), member(F, [pico, vale])))]) :-
    once(intervalo(R, D, F, M)), integer(M), M > 0.

test(hora_invalida) :-
    \+ hora_valida(hora(24, 0)),
    \+ hora_valida(hora(7, 60)),
    \+ hora_valida(sete).

:- end_tests(operacao).
