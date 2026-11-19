# Etapa 03 — Roteador e info_ramal

> **Concluída em 2026-11-19.** `rota/5` (Dijkstra por baldeações → distância → paradas) e `info_ramal/3` implementados. 53 testes passando; todas as 10.506 combinações de estações dão rota nos três tipos de dia.

**Objetivo:** `roteador.pl` com `rota/5` e `info_ramal/3`, devolvendo exatamente o formato do contrato.

**Depende de:** [etapa 02](02-operacao.md).
**Spec:** [spec/roteador.md](../spec/roteador.md) e [spec/contrato-python.md](../spec/contrato-python.md).

## Passos

1. Validar a entrada: resolver origem e destino com `resolver_local/2` e conferir o dia e a hora. Cada falha vira o `erro(...)` do contrato.
2. Escrever as arestas do grafo `no(Estacao, Ramal)`, com andar e baldear, usando `para_em/4` da etapa 02.
3. Escrever a BFS por camadas de baldeação, com conjunto de visitados e limite de 3 baldeações.
4. Converter o caminho cru em `passos([...])`: juntar estações seguidas do mesmo ramal num único `embarque`, calcular `sentido` e `paradas(N)`, e inserir `baldeacao`.
5. Gerar avisos (expresso, parador, bairro usado, trecho fechado) e alternativas (o outro ponto de baldeação).
6. Escrever `info_ramal/3` montando o termo `info(...)` a partir dos fatos da etapa 02.
7. Embrulhar tudo em `once/1` e `catch/3`, para que a consulta nunca falhe nem lance exceção.

## Critérios de aceite

- `rota(piedade, nilopolis, segunda_a_sexta, hora(7,30), R)` dá 1 baldeação, em madureira, de deodoro para japeri.
- `rota(piedade, nilopolis, sabado, hora(10,0), R)` dá 0 baldeações, japeri direto, com o aviso `parador`.
- `rota(piedade, centro, sabado, hora(10,0), R)` sai em `sentido(central_do_brasil)` e tem destino `central_do_brasil`, com o aviso `destino_por_bairro(centro, central_do_brasil)`.
- `rota(bangu, duque_de_caxias, segunda_a_sexta, hora(8,0), R)` faz 1 baldeação, de santa_cruz para saracuruna, na central, em sao_cristovao ou no maracana (deu maracana).
- `rota(meier, meier, ...)` dá `erro(mesma_estacao(meier))`.
- `rota(meier, japeri, segunda_a_sexta, hora(2,0), R)` dá `erro(fora_de_operacao(...))`.
- Nenhuma consulta trava (a busca sempre termina).

## Fora desta etapa

Tempo estimado de viagem e horário exato do próximo trem. Ficam para o backlog, se o Gabriel pedir.
