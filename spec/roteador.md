# Roteador e info_ramal (roteador.pl)

Atende a seção 3 do [pedido original](../pedido-original.md). O código está em [`src/roteador.pl`](../src/roteador.pl). Usa os dados de [dados.md](dados.md) e as regras de [operacao.md](operacao.md). O formato de saída está em [contrato-python.md](contrato-python.md) (não repetido aqui).

## Entradas

`rota(Origem, Destino, Dia, Hora, Resposta)`

- A ordem de validação é: dia → hora → origem → destino → mesma estação. O primeiro problema vira o `erro(...)`.
- `Origem` e `Destino` podem ser estação, apelido ou bairro (`resolver_local/2`).

## Grafo

- Nó = `no(Estacao, Ramal)`. Só entram os ramais rodando naquela hora e só as estações onde cada um **para** naquele momento (`para_em/4`). Assim, no expresso, piedade não existe para o japeri.
- **Andar:** de uma parada para a parada vizinha do mesmo ramal, nos dois sentidos.
- **Baldear:** de `no(E, R1)` para `no(E, R2)` quando os dois param em E agora. Pode ser em qualquer estação onde os dois param, não só nas de `integracao/1`.
- A viagem começa em **todos** os ramais que param na origem, sem custo. Por isso, ficar no mesmo trem do trecho comum não conta como baldeação: no sábado, de piedade a nilopolis é japeri direto.

## Busca

Dijkstra com prioridade `p(Baldeacoes, Distancia, Paradas)`, comparada nessa ordem:

1. **menos baldeações**;
2. empate → **menos estações percorridas** (distância física no ramal, contando as que o expresso pula). Isso impede voltar para trás atrás de um expresso;
3. empate → **menos paradas** (prefere o expresso).

Nó já expandido não é expandido de novo, então a busca sempre termina. Há um limite de 3 baldeações. Com a malha atual, todas as 10.506 combinações de estações têm rota, nos três tipos de dia (conferido em 2026-11-19).

## Sentido

- Indo para posições maiores → `sentido(terminal do ramal)`.
- Indo para posições menores → `sentido(início do ramal)`: `central_do_brasil` nos principais, a estação de conexão nas extensões.

## Caso exigido: Piedade → ramal japeri, dia útil

`rota(piedade, nilopolis, segunda_a_sexta, hora(7,30), R)` devolve:

1. `embarque(deodoro, sentido(deodoro), piedade, madureira, paradas(3))`
2. `baldeacao(madureira, de(deodoro), para(japeri))`
3. `embarque(japeri, sentido(japeri), madureira, nilopolis, paradas(5))`

com o aviso `expresso(japeri, central_do_brasil, deodoro)` e a alternativa `baldeacao(deodoro, de(deodoro), para(japeri))`.

No sábado, a mesma pergunta dá `embarque(japeri, sentido(japeri), piedade, nilopolis, paradas(11))`, sem baldeação, com o aviso `parador(japeri, sabado)`.

Do Méier, em dia útil, a troca sai em **engenho_de_dentro** (a primeira parada do expresso), com Madureira e Deodoro como alternativas.

## Avisos e alternativas

- `expresso`/`parador` só aparecem quando o trecho percorrido naquele ramal passa por dentro de Central–Deodoro. Nova Iguaçu → Paracambi não recebe aviso de expresso.
- Alternativa = outra estação de integração **mais adiante** no sentido da viagem, onde os dois ramais da troca também param agora.

## info_ramal/3

Monta o termo `info(...)` do contrato a partir de `operacao.pl`: a janela de operação, os intervalos de pico e vale, o modo (`expresso(I, F)` quando o ramal tem trecho expresso e o dia tem janela de expresso; senão `parador`), as estações de integração do ramal em ordem e as observações.

## Fora do escopo

Tempo estimado de viagem, horário exato do próximo trem, baldeação a pé (Madureira ↔ Mercadão de Madureira) e integração com metrô e BRT.
