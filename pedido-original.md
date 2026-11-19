# Pedido original

Texto enviado pelo Gabriel em 2026-11-19, sem alterações. É a fonte de tudo em `spec/` e `etapas/`.

---

Atue como um Engenheiro de Software Sênior especialista em Programação Lógica e SWI-Prolog. Preciso que você crie o núcleo de regras de negócio e base de conhecimento em Prolog para um sistema de mobilidade urbana estilo "Moovit", focado exclusivamente na malha ferroviária da SuperVia (Rio de Janeiro).
Contexto de Arquitetura
Este código Prolog será o "cérebro" lógico de uma aplicação maior. Haverá uma camada em Python integrada a uma API de LLM que traduzirá perguntas em linguagem natural do usuário (ex: "Estou em Piedade e quero ir para o Centro no sábado") para consultas estruturadas em Prolog, e depois traduzirá a resposta do Prolog de volta para o usuário. Portanto, os predicados principais de consulta devem retornar estruturas limpas, previsíveis e fáceis de parsear pelo Python (como listas de passos, átomos e termos compostos).
O que você deve construir em SWI-Prolog:

1. Base de Conhecimento Completa da SuperVia (Fatos):
   * Ramais e Extensões: Modele todos os ramais principais (`deodoro`, `santa_cruz`, `japeri`, `belford_roxo`, `saracuruna`) e suas extensões (`paracambi`, `vila_inhomirim`, `guapimirim`).
   * Estações e Sequência: Cadastre as estações de cada ramal em ordem geográfica/sequencial correta (do ponto inicial até o terminal), identificando claramente as estações de integração/baldeação (ex: `central_do_brasil`, `sao_cristovao`, `maracana`, `madureira`, `deodoro`, `gramacho`, `japeri`, etc.).
   * Mapeamento Bairro/Local -> Estação: Crie fatos associando bairros, pontos de referência e localidades à estação mais próxima (ex: `bairro_estacao(piedade, piedade)`, `bairro_estacao(centro, central_do_brasil)`, `bairro_estacao(meier, meier)`), permitindo que o sistema descubra a estação de origem/destino mesmo se o usuário informar apenas o bairro.
2. Regras de Operação e Calendário (Regras Temporais e de Serviço):
   * Modele o funcionamento distinto para `segunda_a_sexta`, `sabado` e `domingo_feriado`.
   * Horários e Intervalos: Defina faixas de horário de operação (início e fim da operação por ramal e dia da semana) e intervalos médios (headway).
   * Comportamento Expresso vs. Parador: Implemente a regra real de negócio da SuperVia:
      * De `segunda_a_sexta` (horário comercial/pico), os ramais `japeri` e `santa_cruz` operam como expressos entre Central do Brasil e Deodoro (parando apenas em estações específicas como São Cristóvão, Maracanã, Olímpica de Engenho de Dentro, Madureira e Deodoro), enquanto o ramal `deodoro` atende as estações intermediárias (como Piedade, Méier, Riachuelo, etc.).
      * Aos `sabados`, `domingos_feriados` ou horários de madrugada/vale, ramais expressos passam a operar como paradores em todo o trecho (ou sofrem alterações de integração em Deodoro/Gramacho). O sistema deve saber explicar e aplicar essa diferença na rota.
3. Motor de Roteamento e Inferência (Estilo Moovit):
   * Crie predicados de busca de rota (usando busca em largura/BFS ou caminho mais curto minimizando baldeações) entre qualquer `Origem` e `Destino`, considerando `DiaDaSemana` e `Hora`.
   * Identificação de Sentido: O sistema deve deduzir automaticamente a plataforma/direção correta que o passageiro deve embarcar (ex: `sentido(central_do_brasil)` ou `sentido(santa_cruz)`).
   * Lógica de Baldeação: Se a origem estiver em uma estação atendida apenas pelo parador (ex: `piedade`) e o destino estiver no ramal `japeri` em uma segunda-feira, o sistema deve instruir: pegar o ramal `deodoro` sentido `deodoro`, descer em `madureira` ou `deodoro`, e fazer baldeação para o ramal `japeri` sentido `japeri`.
   * Explicação do Dia a Dia do Ramal: Crie um predicado `info_ramal(Ramal, DiaDaSemana, Detalhes)` que retorne o resumo operacional daquele ramal no dia solicitado (horário de funcionamento, se é expresso ou parador, e observações de integração).
4. Formato de Saída e Boas Práticas:
   * Organize o código de forma modular e bem comentada (pode separar em arquivos como `estacoes.pl`, `operacao.pl` e `roteador.pl` ou estruturar em um único arquivo `.pl` limpo e bem dividido).
   * Evite loops infinitos na busca em grafo (controle de estações visitadas).
   * Ao final do código, inclua uma seção de Exemplos de Consultas (Queries) prontas para testar cenários reais (ex: trajeto direto, trajeto com baldeação em dia útil vs. fim de semana, consulta de funcionamento de ramal e consulta fora do horário de operação).
