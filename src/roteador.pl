/*  roteador.pl — busca de rota e info_ramal/3.
    Spec: spec/roteador.md. Formato de saída: spec/contrato-python.md.

    As consultas públicas sempre terminam com sucesso, uma vez só,
    devolvendo ok(...) ou erro(...). Nunca lançam exceção para o Python.
*/
:- module(roteador, [
    rota/5,         % +Origem, +Destino, +Dia, +Hora, -Resposta
    info_ramal/3    % +Ramal, +Dia, -Resposta
]).

:- use_module(library(heaps)).
:- use_module(library(assoc)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(yall)).
:- use_module(estacoes).
:- use_module(operacao).

max_baldeacoes(3).
aviso_ultima_viagem_min(30).

/* ------------------------------------------------------------------
   rota/5
   ------------------------------------------------------------------ */

rota(Origem, Destino, Dia, Hora, Resposta) :-
    catch(once(rota_(Origem, Destino, Dia, Hora, R)),
          Erro, R = erro(interno(Erro))),
    Resposta = R.

rota_(O, D, Dia, Hora, R) :-
    (   \+ dia_ok(Dia)               -> R = erro(dia_invalido(Dia))
    ;   \+ hora_valida(Hora)         -> R = erro(hora_invalida(Hora))
    ;   resolver_local(O, RO), RO = erro(E1) -> R = erro(E1)
    ;   resolver_local(D, RD), RD = erro(E2) -> R = erro(E2)
    ;   resolver_local(O, ok(estacao(EO))),
        resolver_local(D, ok(estacao(ED))),
        (   EO == ED
        ->  R = erro(mesma_estacao(EO))
        ;   rota_entre(O, D, EO, ED, Dia, Hora, R)
        )
    ).

dia_ok(Dia) :- atom(Dia), dia(Dia).

rota_entre(O, D, EO, ED, Dia, Hora, R) :-
    paradas_ativas(Dia, Hora, Paradas),
    (   buscar(EO, ED, Paradas, Caminho)
    ->  montar_rota(O, D, EO, ED, Dia, Hora, Caminho, R)
    ;   ramal_fechado_em(EO, ED, Dia, Hora)
    ->  proxima_abertura(Dia, Hora, Abre),
        R = erro(fora_de_operacao(Dia, Hora, Abre))
    ;   R = erro(sem_rota(EO, ED))
    ).

% Algum ramal que atende a origem ou o destino está fechado agora.
ramal_fechado_em(EO, ED, Dia, Hora) :-
    member(E, [EO, ED]),
    estacao_ramal(E, Ramal, _),
    \+ em_operacao(Ramal, Dia, Hora),
    !.

% Ramal-ListaDeParadas (em ordem de posição) dos ramais rodando agora.
paradas_ativas(Dia, Hora, Paradas) :-
    findall(Ramal-Ls,
            ( ramal(Ramal, _),
              em_operacao(Ramal, Dia, Hora),
              findall(E, ( estacao_ramal(E, Ramal, _),
                           once(para_em(Ramal, E, Dia, Hora)) ), Ls),
              Ls = [_, _|_] ),
            Paradas).

/* ------------------------------------------------------------------
   Busca: Dijkstra sobre no(Estacao, Ramal).
   Prioridade p(Baldeacoes, Distancia, Paradas), comparada em ordem:
   menos baldeações, depois menos estações percorridas (distância física
   no ramal), depois menos paradas (prefere o expresso no empate).
   Nós já visitados não são expandidos de novo, então não há loop.
   ------------------------------------------------------------------ */

buscar(EO, ED, Paradas, Caminho) :-
    list_to_assoc(Paradas, PorRamal),
    findall(no(EO, R), ( member(R-Ls, Paradas), memberchk(EO, Ls) ), Inicios),
    Inicios \== [],
    empty_heap(H0),
    foldl([N, Hi, Ho]>>add_to_heap(Hi, p(0, 0, 0), [N], Ho), Inicios, H0, H1),
    empty_assoc(Vis),
    dijkstra(H1, ED, PorRamal, Paradas, Vis, CaminhoRev),
    reverse(CaminhoRev, Caminho).

dijkstra(H0, ED, PorRamal, Paradas, Vis0, Caminho) :-
    get_from_heap(H0, Prio, Path, H1),
    Path = [No|_],
    (   get_assoc(No, Vis0, _)
    ->  dijkstra(H1, ED, PorRamal, Paradas, Vis0, Caminho)
    ;   No = no(ED, _)
    ->  Caminho = Path
    ;   put_assoc(No, Vis0, true, Vis1),
        findall(P2-[N2|Path], vizinho(No, Prio, PorRamal, Paradas, N2, P2), Prox),
        foldl([P-X, Hi, Ho]>>add_to_heap(Hi, P, X, Ho), Prox, H1, H2),
        dijkstra(H2, ED, PorRamal, Paradas, Vis1, Caminho)
    ).

% Andar até a próxima parada do mesmo ramal (nos dois sentidos).
vizinho(no(E, R), p(B, K, S), PorRamal, _, no(E2, R), p(B, K1, S1)) :-
    get_assoc(R, PorRamal, Ls),
    ( nextto(E, E2, Ls) ; nextto(E2, E, Ls) ),
    estacao_ramal(E, R, P1),
    estacao_ramal(E2, R, P2),
    K1 is K + abs(P2 - P1),
    S1 is S + 1.
% Baldear para outro ramal que para na mesma estação agora.
vizinho(no(E, R), p(B, K, S), _, Paradas, no(E, R2), p(B1, K, S)) :-
    max_baldeacoes(Max),
    B < Max,
    member(R2-Ls2, Paradas),
    R2 \== R,
    memberchk(E, Ls2),
    B1 is B + 1.

/* ------------------------------------------------------------------
   Montagem da resposta
   ------------------------------------------------------------------ */

montar_rota(O, D, EO, ED, Dia, Hora, Caminho, R) :-
    segmentos(Caminho, Segs),
    passos(Segs, Passos),
    length(Segs, NSegs),
    Baldeacoes is NSegs - 1,
    avisos(O, D, EO, ED, Segs, Dia, Hora, Avisos),
    alternativas(Segs, Dia, Hora, Alts),
    R = ok(rota(origem(EO), destino(ED), passos(Passos),
                baldeacoes(Baldeacoes), avisos(Avisos), alternativas(Alts))).

% Junta nós seguidos do mesmo ramal: seg(Ramal, [De, ..., Ate]).
segmentos([no(E, R)|T], Segs) :- seg_(T, R, [E], Segs).

seg_([], R, Acc, [seg(R, Es)]) :- reverse(Acc, Es).
seg_([no(E, R)|T], R, Acc, Segs) :- !, seg_(T, R, [E|Acc], Segs).
seg_([no(E, R2)|T], R, Acc, [seg(R, Es)|Segs]) :-
    reverse(Acc, Es),
    seg_(T, R2, [E], Segs).

passos([Seg], [Emb]) :- !, embarque(Seg, Emb).
passos([Seg1, Seg2|T], [Emb, baldeacao(E, de(R1), para(R2))|Ps]) :-
    embarque(Seg1, Emb),
    Seg1 = seg(R1, Es1), last(Es1, E),
    Seg2 = seg(R2, _),
    passos([Seg2|T], Ps).

embarque(seg(R, Es), embarque(R, sentido(S), De, Ate, paradas(N))) :-
    Es = [De|_],
    last(Es, Ate),
    length(Es, L), N is L - 1,
    sentido(R, De, Ate, S).

% Indo para posições maiores: terminal; para menores: início do ramal.
sentido(R, De, Ate, S) :-
    estacao_ramal(De, R, P1),
    estacao_ramal(Ate, R, P2),
    (   P2 > P1 -> terminal(R, S) ; inicio(R, S) ).

avisos(O, D, EO, ED, Segs, Dia, Hora, Avisos) :-
    findall(A, aviso(O, D, EO, ED, Segs, Dia, Hora, A), Avisos0),
    list_to_set(Avisos0, Avisos).

aviso(O, _, EO, _, _, _, _, origem_por_bairro(O, EO))  :- O \== EO.
aviso(_, D, _, ED, _, _, _, destino_por_bairro(D, ED)) :- D \== ED.
aviso(_, _, _, _, Segs, Dia, Hora, expresso(R, De, Ate)) :-
    member(Seg, Segs),
    usa_trecho_expresso(Seg, R, De, Ate),
    modo(R, Dia, Hora, expresso).
aviso(_, _, _, _, Segs, Dia, Hora, parador(R, Dia)) :-
    member(Seg, Segs),
    usa_trecho_expresso(Seg, R, _, _),
    modo(R, Dia, Hora, parador).
aviso(_, _, _, _, Segs, Dia, Hora, ultima_viagem_proxima(R)) :-
    member(seg(R, _), Segs),
    operacao(R, Dia, _, Fim),
    minutos(Fim, F), minutos(Hora, T),
    aviso_ultima_viagem_min(Lim),
    F - T =< Lim.

% O trecho percorrido no ramal passa por dentro do trecho expresso
% (ao menos uma estação antes do fim dele).
usa_trecho_expresso(seg(R, Es), R, De, Ate) :-
    trecho_expresso(R, De, Ate),
    estacao_ramal(Ate, R, PAte),
    member(E, Es),
    estacao_ramal(E, R, P),
    P < PAte,
    !.

% Outro ponto onde a mesma troca R1 -> R2 também funciona: estação de
% integração mais adiante no sentido da viagem, onde os dois param agora.
alternativas(Segs, Dia, Hora, Alts) :-
    findall(alternativa(baldeacao(E2, de(R1), para(R2))),
            ( nextto(seg(R1, Es1), seg(R2, Es2), Segs),
              last(Es1, E), last(Es2, Ate2),
              integracao(E2), E2 \== E, E2 \== Ate2,
              entre(R2, E, E2, Ate2),
              Es1 = [De1|_], adiante(R1, De1, E, E2),
              para_em(R1, E2, Dia, Hora),
              para_em(R2, E2, Dia, Hora) ),
            Alts0),
    list_to_set(Alts0, Alts).

% E2 fica estritamente entre A e B no ramal R.
entre(R, A, E2, B) :-
    estacao_ramal(A, R, PA), estacao_ramal(E2, R, P), estacao_ramal(B, R, PB),
    (   PA < PB -> PA < P, P < PB ; PB < P, P < PA ).

% E2 fica depois de E, seguindo o sentido De -> E no ramal R.
adiante(R, De, E, E2) :-
    estacao_ramal(De, R, PD), estacao_ramal(E, R, PE), estacao_ramal(E2, R, P2),
    (   PE >= PD -> P2 > PE ; P2 < PE ).

/* ------------------------------------------------------------------
   info_ramal/3
   ------------------------------------------------------------------ */

info_ramal(Ramal, Dia, Resposta) :-
    catch(once(info_(Ramal, Dia, R)), Erro, R = erro(interno(Erro))),
    Resposta = R.

info_(Ramal, Dia, R) :-
    (   \+ (atom(Ramal), ramal(Ramal, _)) -> R = erro(ramal_desconhecido(Ramal))
    ;   \+ dia_ok(Dia)                    -> R = erro(dia_invalido(Dia))
    ;   operacao(Ramal, Dia, Inicio, Fim),
        once(intervalo(Ramal, Dia, pico, Pico)),
        once(intervalo(Ramal, Dia, vale, Vale)),
        (   trecho_expresso(Ramal, De, Ate), janela_expresso(Dia, JI, JF)
        ->  Modo = expresso(JI, JF), Trecho = trecho_expresso(De, Ate)
        ;   Modo = parador, Trecho = nenhum
        ),
        findall(E, ( estacao_ramal(E, Ramal, _), integracao(E) ), Integracoes),
        findall(Ob, observacao(Ramal, Dia, Ob), Obs),
        R = ok(info(Ramal, Dia, funcionamento(Inicio, Fim),
                    intervalo(pico(Pico), vale(Vale)), modo(Modo), Trecho,
                    integracoes(Integracoes), observacoes(Obs)))
    ).

observacao(R, Dia, expresso_entre_central_e_deodoro) :-
    trecho_expresso(R, _, _), janela_expresso(Dia, _, _).
observacao(R, Dia, parador_fora_da_janela_do_expresso) :-
    trecho_expresso(R, _, _), janela_expresso(Dia, _, _).
observacao(R, Dia, parador_o_dia_todo) :-
    trecho_expresso(R, _, _), \+ janela_expresso(Dia, _, _).
observacao(deodoro, Dia, atende_estacoes_que_o_expresso_pula) :-
    janela_expresso(Dia, _, _).
observacao(R, _, baldeacao_obrigatoria(Conexao)) :-
    extensao_de(R, _, Conexao).
observacao(R, _, extensao(X, em(Conexao))) :-
    extensao_de(X, R, Conexao).
