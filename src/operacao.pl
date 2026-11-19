/*  operacao.pl — calendário, horários, intervalos e expresso × parador.
    Spec: spec/operacao.md. Os valores numéricos ficam todos na seção
    "Valores" para serem corrigidos sem mexer nas regras.

    Hora sempre como hora(H, M). Por dentro, tudo vira minutos desde 00:00.
*/
:- module(operacao, [
    dia/1,                 % ?Dia            segunda_a_sexta | sabado | domingo_feriado
    hora_valida/1,         % +Hora
    minutos/2,             % +Hora, -Minutos
    operacao/4,            % ?Ramal, ?Dia, ?Inicio, ?Fim
    intervalo/4,           % ?Ramal, ?Dia, ?Faixa, ?Minutos
    faixa/4,               % ?Dia, ?Faixa, ?Inicio, ?Fim  (só as faixas de pico)
    paradas_expresso/1,    % ?Estacao
    trecho_expresso/3,     % ?Ramal, ?De, ?Ate
    janela_expresso/3,     % ?Dia, ?Inicio, ?Fim
    em_operacao/3,         % +Ramal, +Dia, +Hora
    faixa_atual/3,         % +Dia, +Hora, -Faixa      pico | vale
    modo/4,                % +Ramal, +Dia, +Hora, -Modo  expresso | parador
    para_em/4,             % ?Ramal, ?Estacao, +Dia, +Hora
    proxima_abertura/3     % +Dia, +Hora, -Abre
]).

:- use_module(estacoes).

/* ------------------------------------------------------------------
   Calendário e hora
   ------------------------------------------------------------------ */

dia(segunda_a_sexta).
dia(sabado).
dia(domingo_feriado).

hora_valida(hora(H, M)) :-
    integer(H), integer(M),
    H >= 0, H =< 23, M >= 0, M =< 59.

minutos(hora(H, M), T) :- T is H * 60 + M.

% Inicio =< Hora < Fim
dentro(Hora, Inicio, Fim) :-
    minutos(Hora, T), minutos(Inicio, I), minutos(Fim, F),
    T >= I, T < F.

/* ------------------------------------------------------------------
   Valores. Fontes e o que é aproximado: spec/operacao.md.
   ------------------------------------------------------------------ */

% Janela de operação por tipo de ramal.
janela(principal, segunda_a_sexta, hora(4, 30), hora(23, 0)).
janela(principal, sabado,          hora(5, 0),  hora(22, 0)).
janela(principal, domingo_feriado, hora(5, 0),  hora(21, 0)).
janela(extensao,  segunda_a_sexta, hora(5, 0),  hora(21, 0)).
janela(extensao,  sabado,          hora(5, 0),  hora(20, 0)).
janela(extensao,  domingo_feriado, hora(5, 0),  hora(20, 0)).

% Ramal com horário próprio (vence a janela geral).
janela_ramal(belford_roxo, domingo_feriado, hora(5, 0), hora(17, 20)).

operacao(Ramal, Dia, Inicio, Fim) :-
    ramal(Ramal, Tipo),
    dia(Dia),
    (   janela_ramal(Ramal, Dia, I0, F0)
    ->  Inicio = I0, Fim = F0
    ;   janela(Tipo, Dia, Inicio, Fim)
    ).

% Faixas de pico de dia útil (usadas para o intervalo). Fora delas é vale.
faixa(segunda_a_sexta, pico, hora(6, 0),  hora(8, 0)).
faixa(segunda_a_sexta, pico, hora(17, 0), hora(19, 0)).

% Quando Japeri e Santa Cruz rodam expressos entre Central e Deodoro.
% Fonte (2024): em dia útil, até 21h, os trens do tronco são expressos.
janela_expresso(segunda_a_sexta, hora(4, 30), hora(21, 0)).

% Intervalo médio em minutos.
intervalo_base(deodoro,      segunda_a_sexta, pico, 10).
intervalo_base(deodoro,      segunda_a_sexta, vale, 20).
intervalo_base(japeri,       segunda_a_sexta, pico, 8).
intervalo_base(santa_cruz,   segunda_a_sexta, pico, 9).
intervalo_base(belford_roxo, segunda_a_sexta, pico, 15).
intervalo_base(saracuruna,   segunda_a_sexta, pico, 12).
intervalo_base(belford_roxo, domingo_feriado, _,    50).

intervalo(Ramal, Dia, Faixa, Min) :-
    ramal(Ramal, Tipo),
    dia(Dia),
    member(Faixa, [pico, vale]),
    (   intervalo_base(Ramal, Dia, Faixa, M0) -> Min = M0
    ;   intervalo_padrao(Tipo, Dia, Min)
    ).

intervalo_padrao(principal, segunda_a_sexta, 20).
intervalo_padrao(principal, sabado,          25).
intervalo_padrao(principal, domingo_feriado, 35).
intervalo_padrao(extensao,  _,               60).

% Onde o expresso para entre Central e Deodoro (Diário do Rio, 27/01/2026).
paradas_expresso(central_do_brasil).
paradas_expresso(sao_cristovao).
paradas_expresso(maracana).
paradas_expresso(silva_freire).
paradas_expresso(engenho_de_dentro).
paradas_expresso(madureira).
paradas_expresso(deodoro).

trecho_expresso(japeri,     central_do_brasil, deodoro).
trecho_expresso(santa_cruz, central_do_brasil, deodoro).

/* ------------------------------------------------------------------
   Regras
   ------------------------------------------------------------------ */

em_operacao(Ramal, Dia, Hora) :-
    operacao(Ramal, Dia, Inicio, Fim),
    dentro(Hora, Inicio, Fim).

faixa_atual(Dia, Hora, Faixa) :-
    (   faixa(Dia, pico, Inicio, Fim), dentro(Hora, Inicio, Fim)
    ->  Faixa = pico
    ;   Faixa = vale
    ).

% Expresso só dentro de janela_expresso/3, nos ramais com trecho_expresso/3.
modo(Ramal, Dia, Hora, Modo) :-
    ramal(Ramal, _),
    (   trecho_expresso(Ramal, _, _),
        janela_expresso(Dia, Inicio, Fim),
        dentro(Hora, Inicio, Fim)
    ->  Modo = expresso
    ;   Modo = parador
    ).

% O ramal está rodando e para nessa estação nesse momento.
para_em(Ramal, Estacao, Dia, Hora) :-
    estacao_ramal(Estacao, Ramal, Pos),
    em_operacao(Ramal, Dia, Hora),
    (   modo(Ramal, Dia, Hora, expresso),
        trecho_expresso(Ramal, De, Ate),
        estacao_ramal(De, Ramal, PDe),
        estacao_ramal(Ate, Ramal, PAte),
        Pos >= PDe, Pos =< PAte
    ->  paradas_expresso(Estacao)
    ;   true
    ).

% shortcut: depois do último trem, devolve a primeira abertura do mesmo tipo
% de dia (o Prolog não sabe qual é o dia seguinte); o Python ajusta se mudar.
proxima_abertura(Dia, Hora, abre(Abre)) :-
    minutos(Hora, T),
    findall(I-Inicio, ( operacao(_, Dia, Inicio, _), minutos(Inicio, I) ), Todos),
    (   include([I-_]>>(I > T), Todos, Depois), Depois \== []
    ->  min_member(_-Abre, Depois)
    ;   min_member(_-Abre, Todos)
    ).
