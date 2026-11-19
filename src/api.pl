/*  api.pl — ponte JSON para o Python (spec/app-desktop.md).
    Uso: echo '{"acao":"rota", ...}' | swipl src/api.pl

    Lê um JSON do stdin, chama rota/5, info_ramal/3 ou resolver_local/2
    e escreve a resposta em JSON no stdout. O Python nunca manda código
    Prolog: só dados, que viram átomos aqui.

    Conversão termo -> JSON (genérica, não muda o contrato):
      átomo -> string, número -> número, lista -> array,
      f(X) -> {"f": X},  f(X, Y, ...) -> {"f": [X, Y, ...]}
*/
:- use_module(library(json)).
:- use_module(estacoes).
:- use_module(operacao).
:- use_module(roteador).

:- initialization(main, main).

main :-
    set_stream(user_input,  encoding(utf8)),
    set_stream(user_output, encoding(utf8)),
    catch(( read_string(user_input, _, Texto0),
            sem_bom(Texto0, Texto),
            atom_json_dict(Texto, Pedido, []),
            responder(Pedido, Termo) ),
          Erro,
          ( format(string(Msg), "~q", [Erro]), Termo = erro(interno(Msg)) )),
    termo_json(Termo, Json),
    json_write_dict(user_output, Json, [width(0)]),
    nl.

% O PowerShell põe um BOM (U+FEFF) na frente do que manda pelo pipe.
sem_bom(S0, S) :-
    (   sub_string(S0, 0, 1, _, "﻿")
    ->  sub_string(S0, 1, _, 0, S)
    ;   S = S0
    ).

/* ------------------------------------------------------------------
   Ações
   ------------------------------------------------------------------ */

responder(P, T) :-
    campo(acao, P, Acao),
    (   Acao == rota
    ->  campo(origem, P, O), campo(destino, P, D), campo(dia, P, Dia),
        get_dict(hora, P, H0), hora_de(H0, H),
        rota(O, D, Dia, H, T)
    ;   Acao == info_ramal
    ->  campo(ramal, P, R), campo(dia, P, Dia),
        info_ramal(R, Dia, T)
    ;   Acao == ramais_do_dia
    ->  campo(dia, P, Dia),
        ramais_do_dia(Dia, T)
    ;   Acao == resolver_local
    ->  campo(local, P, L),
        resolver_local(L, T)
    ;   Acao == locais
    ->  locais(T)
    ;   T = erro(acao_desconhecida(Acao))
    ).

% info_ramal/3 dos ramais principais, para a barra lateral do app.
ramais_do_dia(Dia, T) :-
    findall(R, ramal(R, principal), Rs),
    maplist([R, I]>>info_ramal(R, Dia, I), Rs, Is),
    (   memberchk(erro(E), Is)
    ->  T = erro(E)
    ;   maplist([ok(X), X]>>true, Is, Infos),
        T = ok(ramais(Infos))
    ).

% Todos os nomes que resolver_local/2 entende (para o prompt da LLM).
locais(ok(locais(estacoes(Es), apelidos(As), bairros(Bs)))) :-
    findall(E, estacao_ramal(E, _, _), Es0), sort(Es0, Es),
    findall(A, apelido(A, _), As0), sort(As0, As),
    findall(B, bairro_estacao(B, _), Bs0), sort(Bs0, Bs).

% Campo obrigatório, como átomo (string do JSON -> átomo).
campo(K, P, V) :-
    (   get_dict(K, P, V0)
    ->  para_atomo(V0, V)
    ;   throw(campo_ausente(K))
    ).

para_atomo(S, A) :- string(S), !, atom_string(A, S).
para_atomo(X, X).

% [H, M] -> hora(H, M). Qualquer outra coisa segue como veio, e rota/5
% responde erro(hora_invalida(...)).
hora_de([H, M], hora(H, M)) :- !.
hora_de(X, X).

/* ------------------------------------------------------------------
   Termo -> JSON
   ------------------------------------------------------------------ */

termo_json(X, X) :- number(X), !.
termo_json(X, S) :- atom(X), !, atom_string(X, S).
termo_json(X, X) :- string(X), !.
termo_json(X, null) :- var(X), !.
termo_json(L, J) :- is_list(L), !, maplist(termo_json, L, J).
termo_json(T, J) :-
    compound_name_arguments(T, F, Args),
    (   Args = [A] -> termo_json(A, V) ; maplist(termo_json, Args, V) ),
    dict_create(J, _, [F-V]).
