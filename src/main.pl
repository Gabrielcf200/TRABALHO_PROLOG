/*  main.pl — ponto de entrada. Carrega o núcleo inteiro.
    Uso: swipl src/main.pl     (depois, cole as consultas abaixo)
    Formato das respostas: spec/contrato-python.md
*/
:- use_module(estacoes).
:- use_module(operacao).
:- use_module(roteador).

/* ======================================================================
   EXEMPLOS DE CONSULTAS
   As respostas abaixo são as reais (geradas em 2026-11-19) e são
   conferidas pelos testes em testes/testes.pl.
   ======================================================================

   1. Trajeto direto (sentido Central)
   ?- rota(meier, central_do_brasil, segunda_a_sexta, hora(9,0), R).
   R = ok(rota(origem(meier), destino(central_do_brasil),
               passos([embarque(deodoro, sentido(central_do_brasil),
                                meier, central_do_brasil, paradas(8))]),
               baldeacoes(0), avisos([]), alternativas([]))).

   2. Baldeação em dia útil: Piedade não é atendida pelo expresso de Japeri
   ?- rota(piedade, nilopolis, segunda_a_sexta, hora(7,30), R).
   R = ok(rota(origem(piedade), destino(nilopolis),
               passos([embarque(deodoro, sentido(deodoro), piedade, madureira, paradas(3)),
                       baldeacao(madureira, de(deodoro), para(japeri)),
                       embarque(japeri, sentido(japeri), madureira, nilopolis, paradas(5))]),
               baldeacoes(1),
               avisos([expresso(japeri, central_do_brasil, deodoro)]),
               alternativas([alternativa(baldeacao(deodoro, de(deodoro), para(japeri)))]))).

   3. A mesma viagem no sábado: Japeri vira parador, sem baldeação
   ?- rota(piedade, nilopolis, sabado, hora(10,0), R).
   R = ok(rota(origem(piedade), destino(nilopolis),
               passos([embarque(japeri, sentido(japeri), piedade, nilopolis, paradas(11))]),
               baldeacoes(0), avisos([parador(japeri, sabado)]), alternativas([]))).

   4. Funcionamento do ramal em dia útil
   ?- info_ramal(japeri, segunda_a_sexta, R).
   R = ok(info(japeri, segunda_a_sexta,
               funcionamento(hora(4,30), hora(23,0)),
               intervalo(pico(8), vale(20)),
               modo(expresso(hora(4,30), hora(21,0))),
               trecho_expresso(central_do_brasil, deodoro),
               integracoes([central_do_brasil, sao_cristovao, maracana,
                            engenho_de_dentro, madureira, deodoro, japeri]),
               observacoes([expresso_entre_central_e_deodoro,
                            parador_fora_da_janela_do_expresso,
                            extensao(paracambi, em(japeri))]))).

   5. Funcionamento do mesmo ramal no domingo
   ?- info_ramal(japeri, domingo_feriado, R).
   R = ok(info(japeri, domingo_feriado,
               funcionamento(hora(5,0), hora(21,0)),
               intervalo(pico(35), vale(35)),
               modo(parador), nenhum,
               integracoes([central_do_brasil, sao_cristovao, maracana,
                            engenho_de_dentro, madureira, deodoro, japeri]),
               observacoes([parador_o_dia_todo, extensao(paracambi, em(japeri))]))).

   6. Fora do horário de operação
   ?- rota(meier, japeri, segunda_a_sexta, hora(2,0), R).
   R = erro(fora_de_operacao(segunda_a_sexta, hora(2,0), abre(hora(4,30)))).

   7. Bairro em vez de estação (Tijuca -> Maracanã)
   ?- rota(tijuca, bangu, sabado, hora(15,0), R).
   R = ok(rota(origem(maracana), destino(bangu),
               passos([embarque(santa_cruz, sentido(santa_cruz), maracana, bangu, paradas(21))]),
               baldeacoes(0),
               avisos([origem_por_bairro(tijuca, maracana), parador(santa_cruz, sabado)]),
               alternativas([]))).

   8. Extensão: entrar em Paracambi exige baldeação em Japeri
   ?- rota(nova_iguacu, paracambi, segunda_a_sexta, hora(10,0), R).
   R = ok(rota(origem(nova_iguacu), destino(paracambi),
               passos([embarque(japeri, sentido(japeri), nova_iguacu, japeri, paradas(5)),
                       baldeacao(japeri, de(japeri), para(paracambi)),
                       embarque(paracambi, sentido(paracambi), japeri, paracambi, paradas(2))]),
               baldeacoes(1), avisos([]), alternativas([]))).

   9. Descobrir a estação de um bairro ou apelido
   ?- resolver_local(engenhao, R).
   R = ok(estacao(engenho_de_dentro)).
*/
