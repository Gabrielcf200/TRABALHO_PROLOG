/*  estacoes.pl — base de dados da malha ferroviária do Rio (SuperVia/TrensRJ).
    Spec: spec/dados.md. Fontes e trechos "a conferir" estão lá.

    A ordem de cada ramal fica numa lista só (sequencia/2), e estacao_ramal/3
    é derivado dela. Assim não existe posição duplicada nem buraco.
*/
:- module(estacoes, [
    ramal/2,            % ?Ramal, ?Tipo                 principal | extensao
    extensao_de/3,      % ?Extensao, ?RamalPai, ?EstacaoDeConexao
    estacao_ramal/3,    % ?Estacao, ?Ramal, ?Posicao   1 = início do ramal
    integracao/1,       % ?Estacao                      estação de baldeação
    apelido/2,          % ?Nome, ?NomeOficial
    bairro_estacao/2,   % ?BairroOuLocal, ?Estacao
    vizinhas/3,         % ?Ramal, ?E1, ?E2              E2 vem logo depois de E1
    inicio/2,           % ?Ramal, ?Estacao
    terminal/2,         % ?Ramal, ?Estacao
    estacao_existe/1,   % +Estacao
    resolver_local/2    % +Texto, -Resposta              ok(estacao(E)) | erro(...)
]).

/* ------------------------------------------------------------------
   Ramais
   ------------------------------------------------------------------ */

ramal(deodoro,        principal).
ramal(santa_cruz,     principal).
ramal(japeri,         principal).
ramal(belford_roxo,   principal).
ramal(saracuruna,     principal).
ramal(paracambi,      extensao).
ramal(vila_inhomirim, extensao).
ramal(guapimirim,     extensao).

extensao_de(paracambi,      japeri,     japeri).
extensao_de(vila_inhomirim, saracuruna, saracuruna).
extensao_de(guapimirim,     saracuruna, saracuruna).

/* ------------------------------------------------------------------
   Sequência das estações (início -> terminal)
   ------------------------------------------------------------------ */

% Tronco Central–Deodoro, como o ramal deodoro (parador) atende.
tronco([central_do_brasil, praca_da_bandeira, sao_cristovao, maracana,
        sao_francisco_xavier, riachuelo, sampaio, engenho_novo, meier,
        engenho_de_dentro, piedade, quintino_bocaiuva, cascadura, madureira,
        oswaldo_cruz, bento_ribeiro, marechal_hermes, deodoro]).

% Japeri e Santa Cruz usam o mesmo tronco e, além dele, param em Silva Freire
% (via do expresso, entre Méier e Engenho de Dentro — a conferir).
tronco_japeri_santa_cruz(T) :-
    tronco(T0),
    once(append(Antes, [engenho_de_dentro|Depois], T0)),
    append(Antes, [silva_freire, engenho_de_dentro|Depois], T).

sequencia(deodoro, L) :- tronco(L).
sequencia(santa_cruz, L) :-
    tronco_japeri_santa_cruz(T),
    append(T, [vila_militar, magalhaes_bastos, realengo, padre_miguel,
               guilherme_da_silveira, bangu, senador_camara, santissimo,
               augusto_vasconcelos, campo_grande, benjamim_do_monte, inhoaiba,
               cosmos, paciencia, tancredo_neves, santa_cruz], L).
sequencia(japeri, L) :-
    tronco_japeri_santa_cruz(T),
    append(T, [ricardo_de_albuquerque, anchieta, olinda, nilopolis,
               edson_passos, mesquita, presidente_juscelino, nova_iguacu,
               comendador_soares, austin, queimados, engenheiro_pedreira,
               japeri], L).
sequencia(belford_roxo,
          [central_do_brasil, sao_cristovao, maracana, triagem, jacarezinho,
           del_castilho, pilares, tomas_coelho, cavalcanti,
           mercadao_de_madureira, rocha_miranda, honorio_gurgel, barros_filho,
           costa_barros, pavuna, vila_rosali, agostinho_porto, coelho_da_rocha,
           belford_roxo]).
sequencia(saracuruna,
          [central_do_brasil, sao_cristovao, maracana, triagem, manguinhos,
           bonsucesso, ramos, olaria, penha, penha_circular, bras_de_pina,
           cordovil, parada_de_lucas, vigario_geral, duque_de_caxias,
           corte_oito, gramacho, campos_eliseos, jardim_primavera,
           saracuruna]).
sequencia(paracambi, [japeri, lages, paracambi]).
sequencia(vila_inhomirim,
          [saracuruna, parada_morabi, imbarie, manoel_belo, parada_angelica,
           piabeta, fragoso, vila_inhomirim]).
% shortcut: a fonte lista Guapimirim a partir de Parque Estrela; a ligação
% Saracuruna -> Parque Estrela está como hipótese até conferir na TrensRJ.
sequencia(guapimirim,
          [saracuruna, parque_estrela, santa_dalila, surui, santa_guilhermina,
           iriri, mage, jardim_nova_marilia, jororo, citrolandia,
           parada_ideal, jardim_guapimirim, parada_modelo, parada_bananal,
           guapimirim]).

% shortcut: recalcula a lista a cada chamada; se o roteador ficar lento,
% materializar com table/1 ou assert na carga.
estacao_ramal(Estacao, Ramal, Posicao) :-
    ramal(Ramal, _),
    sequencia(Ramal, Lista),
    nth1(Posicao, Lista, Estacao).

vizinhas(Ramal, E1, E2) :-
    ramal(Ramal, _),
    sequencia(Ramal, Lista),
    nextto(E1, E2, Lista).

inicio(Ramal, Estacao) :-
    ramal(Ramal, _),
    sequencia(Ramal, [Estacao|_]).

terminal(Ramal, Estacao) :-
    ramal(Ramal, _),
    sequencia(Ramal, Lista),
    last(Lista, Estacao).

estacao_existe(Estacao) :-
    atom(Estacao),
    once(estacao_ramal(Estacao, _, _)).

/* ------------------------------------------------------------------
   Integrações (só estações onde dá para trocar de ramal sem sair)
   ------------------------------------------------------------------ */

integracao(central_do_brasil).
integracao(sao_cristovao).
integracao(maracana).
integracao(triagem).
integracao(engenho_de_dentro).
integracao(madureira).
integracao(deodoro).
integracao(japeri).
integracao(saracuruna).

/* ------------------------------------------------------------------
   Apelidos (nome popular/antigo -> nome usado no sistema)
   ------------------------------------------------------------------ */

apelido(central,                       central_do_brasil).
apelido(lauro_muller,                  praca_da_bandeira).
apelido(olimpica_de_engenho_de_dentro, engenho_de_dentro).
apelido(engenhao,                      engenho_de_dentro).
apelido(quintino,                      quintino_bocaiuva).
apelido(prefeito_bento_ribeiro,        bento_ribeiro).
apelido(mocidade,                      padre_miguel).
apelido(mocidade_padre_miguel,         padre_miguel).
apelido(benjamin_do_monte,             benjamim_do_monte).
apelido(pavuna_sao_joao_de_meriti,     pavuna).
apelido(morabi,                        parada_morabi).
apelido(parada_capim,                  jardim_guapimirim).

/* ------------------------------------------------------------------
   Bairros e pontos de referência -> estação mais próxima.
   Bairro com o mesmo nome de uma estação não precisa de fato aqui:
   resolver_local/2 já acha a estação primeiro.
   ------------------------------------------------------------------ */

bairro_estacao(centro,                 central_do_brasil).
bairro_estacao(saara,                  central_do_brasil).
bairro_estacao(presidente_vargas,      central_do_brasil).
bairro_estacao(cidade_nova,            praca_da_bandeira).
bairro_estacao(tijuca,                 maracana).
bairro_estacao(uerj,                   maracana).
bairro_estacao(estadio_maracana,       maracana).
bairro_estacao(mangueira,              maracana).
bairro_estacao(quinta_da_boa_vista,    sao_cristovao).
bairro_estacao(vila_isabel,            sao_francisco_xavier).
bairro_estacao(estadio_nilton_santos,  engenho_de_dentro).
bairro_estacao(todos_os_santos,        meier).
bairro_estacao(encantado,              piedade).
bairro_estacao(caxias,                 duque_de_caxias).
bairro_estacao(sao_joao_de_meriti,     pavuna).
bairro_estacao(nova_iguacu_centro,     nova_iguacu).
bairro_estacao(baixada,                nova_iguacu).

/* ------------------------------------------------------------------
   resolver_local(+Texto, -Resposta)
   Ordem: estação -> apelido -> bairro. Nunca falha.
   ------------------------------------------------------------------ */

% Calcula antes de unificar com a saída: funciona mesmo se a saída já vier
% preenchida, ex.: resolver_local(meier, erro(_)) falha em vez de mentir.
resolver_local(X, Resposta) :-
    (   estacao_existe(X)                -> R = ok(estacao(X))
    ;   atom(X), apelido(X, E)           -> R = ok(estacao(E))
    ;   atom(X), bairro_estacao(X, E)    -> R = ok(estacao(E))
    ;   R = erro(local_desconhecido(X))
    ),
    Resposta = R.
