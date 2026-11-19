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
